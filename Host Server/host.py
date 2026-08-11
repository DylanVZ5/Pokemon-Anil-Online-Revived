import asyncio
import time
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Iterable

HOST = "0.0.0.0"
PORT = 25565
TIMEOUT_ESPERA = 10 * 60.0  # 10 minutos máximo esperando en una sala

COMMA = ord(",")
BACKSLASH = ord("\\")

def parse_record_line(line: bytes) -> List[bytes]:
    """Separa los datos del juego de forma segura, respetando caracteres especiales."""
    line = line.rstrip(b"\n")
    if line.endswith(b"\r"):
        line = line[:-1]

    fields: List[bytes] = []
    field_bytes = bytearray()
    escape = False

    for byte in line:
        if byte == COMMA and not escape:
            fields.append(bytes(field_bytes))
            field_bytes.clear()
        elif byte == BACKSLASH and not escape:
            escape = True
        else:
            field_bytes.append(byte)
            escape = False

    fields.append(bytes(field_bytes))
    return fields

def escape_field(field_bytes: bytes) -> bytes:
    return field_bytes.replace(b"\\", b"\\\\").replace(b",", b"\\,")

def build_record(fields: Iterable[bytes]) -> bytes:
    return b",".join(escape_field(f) for f in fields) + b"\n"

def text(field_bytes: bytes) -> str:
    return field_bytes.decode("utf-8", errors="replace")

@dataclass
class Client:
    reader: asyncio.StreamReader
    writer: asyncio.StreamWriter
    address: str
    connected_at: float = field(default_factory=time.monotonic)

    version: bytes = b""
    group: bytes = b""
    name: bytes = b""
    trainer_type: bytes = b""
    win_text: bytes = b"0"
    lose_text: bytes = b"0"
    party_fields: List[bytes] = field(default_factory=list)

    matched: asyncio.Future = field(init=False)
    done: asyncio.Future = field(init=False)

    def __post_init__(self) -> None:
        loop = asyncio.get_running_loop()
        self.matched = loop.create_future()
        self.done = loop.create_future()

    @property
    def name_str(self) -> str:
        return text(self.name) if self.name else "Desconocido"

    @property
    def group_str(self) -> str:
        return text(self.group) if self.group else "???"

class ServidorAmigable:
    def __init__(self, host: str, port: int):
        self.host = host
        self.port = port
        self._server: Optional[asyncio.AbstractServer] = None
        self._waiting: Dict[bytes, Client] = {}
        self._active_groups: set = set()
        self._lock = asyncio.Lock()

    async def start(self) -> None:
        self._server = await asyncio.start_server(self.handle_client, self.host, self.port)
        print("==================================================")
        print("🌟 SERVIDOR ONLINE DE POKÉMON INICIADO 🌟")
        print(f"📡 Puerto TCP: {self.port}")
        print("==================================================")
        print("Esperando a que los jugadores se conecten...\n")
        
        async with self._server:
            await self._server.serve_forever()

    async def handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        peer = writer.get_extra_info("peername")
        address = peer[0] if isinstance(peer, tuple) else str(peer)
        client = Client(reader=reader, writer=writer, address=address)
        
        print(f"👋 ¡Un jugador se ha conectado! (IP: {client.address})")

        try:
            line = await asyncio.wait_for(reader.readline(), timeout=30.0)
            if not line:
                return

            fields = parse_record_line(line)
            if len(fields) < 9 or fields[0] != b"find":
                await self.send_disconnect(client, b"Error de protocolo")
                return

            # Extraemos los datos del jugador
            client.version = fields[1]
            client.group = fields[2]
            client.name = fields[3]
            # Omitimos fields[4] (Player ID) para reparar el bug nativo de Añil
            client.trainer_type = fields[5]
            client.win_text = fields[6]
            client.lose_text = fields[7]
            client.party_fields = fields[8:]

            await self.emparejar_jugador(client)
            await client.done
        except asyncio.TimeoutError:
            print(f"⏳ Tiempo de espera agotado para {client.address}.")
        except Exception:
            pass
        finally:
            await self.limpiar_desconexion(client)
            if not client.writer.is_closing():
                client.writer.close()
            if not client.done.done():
                client.done.set_result(None)

    async def emparejar_jugador(self, client: Client) -> None:
        partner: Optional[Client] = None
        action = "esperar"

        async with self._lock:
            if client.group in self._active_groups:
                action = "lleno"
            else:
                partner = self._waiting.get(client.group)
                if partner is None:
                    self._waiting[client.group] = client
                    action = "esperar"
                else:
                    del self._waiting[client.group]
                    self._active_groups.add(client.group)
                    action = "emparejar"

        if action == "lleno":
            print(f"⛔ {client.name_str} intentó entrar a la sala {client.group_str}, pero ya está llena.")
            await self.send_disconnect(client, b"Sala llena")
            return

        if action == "emparejar":
            assert partner is not None
            if not partner.matched.done(): partner.matched.set_result(True)
            if not client.matched.done(): client.matched.set_result(True)
            
            print(f"⚔️ ¡Partida Encontrada en la sala '{client.group_str}'!")
            print(f"🎮 {partner.name_str}  VS  {client.name_str}")
            print(f"🚀 Transmitiendo datos del combate...")
            
            asyncio.create_task(self.iniciar_puente(partner, client))
            return

        print(f"🔍 {client.name_str} ha creado la sala '{client.group_str}' y está esperando a un rival...")

        try:
            await asyncio.wait_for(asyncio.shield(client.matched), TIMEOUT_ESPERA)
        except asyncio.TimeoutError:
            if await self.limpiar_desconexion(client):
                print(f"⏰ {client.name_str} se cansó de esperar en la sala '{client.group_str}'.")
                await self.send_disconnect(client, b"Nadie se unio")

    async def iniciar_puente(self, first: Client, second: Client) -> None:
        try:
            # Enviamos el paquete 'found' reparado (con el b"0" al final) a ambos
            await self.enviar_found_reparado(first, second, b"0")
            await self.enviar_found_reparado(second, first, b"1")

            # Mantenemos la conexión fluyendo en ambas direcciones
            t1 = asyncio.create_task(self.transmitir_datos(first, second))
            t2 = asyncio.create_task(self.transmitir_datos(second, first))
            
            done, pending = await asyncio.wait({t1, t2}, return_when=asyncio.FIRST_COMPLETED)
            
            for task in pending:
                task.cancel()
                
            print(f"🏁 El encuentro en la sala '{text(first.group)}' ha finalizado.")
        except Exception:
            print(f"⚠️ Hubo un error de conexión durante la partida de {first.name_str} y {second.name_str}.")
        finally:
            async with self._lock:
                self._active_groups.discard(first.group)
            if not first.writer.is_closing(): first.writer.close()
            if not second.writer.is_closing(): second.writer.close()
            if not first.done.done(): first.done.set_result(None)
            if not second.done.done(): second.done.set_result(None)

    async def transmitir_datos(self, origen: Client, destino: Client) -> None:
        while True:
            try:
                line = await origen.reader.readline()
                if not line:
                    break
                destino.writer.write(line)
                await destino.writer.drain()
            except Exception:
                break
        
        print(f"🚪 {origen.name_str} ha abandonado la partida.")

    async def enviar_found_reparado(self, client: Client, partner: Client, client_id: bytes) -> None:
        """Construye el paquete de conexión engañando al motor del juego."""
        fields = [
            b"found",
            client_id,
            partner.name,
            partner.trainer_type,
            partner.win_text,
            partner.lose_text,
            *partner.party_fields,
            b"0"  # <- El 0 mágico que evita el crasheo de las reglas
        ]
        client.writer.write(build_record(fields))
        await client.writer.drain()

    async def send_disconnect(self, client: Client, reason: bytes) -> None:
        try:
            client.writer.write(build_record([b"disconnect", reason]))
            await client.writer.drain()
        except Exception:
            pass

    async def limpiar_desconexion(self, client: Client) -> bool:
        async with self._lock:
            if client.group and self._waiting.get(client.group) is client:
                del self._waiting[client.group]
                return True
        return False

if __name__ == "__main__":
    servidor = ServidorAmigable(HOST, PORT)
    try:
        asyncio.run(servidor.start())
    except KeyboardInterrupt:
        print("\n🛑 Servidor apagado manualmente.")