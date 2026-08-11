using System;
using System.IO;
using System.Text;

public class RubyMarshalReader
{
    private BinaryReader reader;

    public RubyMarshalReader(string filePath)
    {
        FileStream fs = new FileStream(filePath, FileMode.Open, FileAccess.Read);
        reader = new BinaryReader(fs);
    }

    public void ParseSaveFile()
    {
        // 1. Validar la cabecera mágica de Ruby Marshal (4.8)
        byte major = reader.ReadByte();
        byte minor = reader.ReadByte();

        if (major != 4 || minor != 8)
        {
            throw new Exception("Error: El archivo no es un archivo serializado de Ruby Marshal 4.8 válido.");
        }

        Console.WriteLine("[+] Cabecera Marshal 4.8 válida detectada.");

        // 2. Leer el primer token principal del archivo
        ReadNextToken();
        
        reader.Close();
    }

    private void ReadNextToken()
    {
        if (reader.BaseStream.Position >= reader.BaseStream.Length) return;

        byte tokenType = reader.ReadByte();

        switch ((char)tokenType)
        {
            case 'o': // Objeto
                Console.WriteLine("[Token] Detectado inicio de Objeto ('o')");
                ParseRubyObject();
                break;

            case ':': // Símbolo (Nombre de variable)
                string symbol = ParseRubySymbol();
                Console.WriteLine($"[Token] Símbolo encontrado: {symbol}");
                break;

            case '[': // Arreglo / Lista
                Console.WriteLine("[Token] Detectado un Arreglo ('[')");
                // Aquí procesarías los elementos de la lista (ej. la party de Pokémon)
                break;

            default:
                Console.WriteLine($"[Token Desconocido] Byte: 0x{tokenType:X2} / Char: {(char)tokenType}");
                break;
        }
    }

    private string ParseRubySymbol()
    {
        // En Ruby Marshal, los símbolos van seguidos de un entero que indica su longitud
        int length = ReadMarshalInteger();
        byte[] stringBytes = reader.ReadBytes(length);
        return Encoding.UTF8.GetString(stringBytes);
    }

    private void ParseRubyObject()
    {
        // Un objeto primero dice qué clase es (un Símbolo)
        // Ejemplo: :Poseidon (si es la clase del motor) o :Pokemon
        ReadNextToken(); 
    }

    private int ReadMarshalInteger()
    {
        // Ruby comprime los enteros pequeños en un solo byte para ahorrar espacio
        sbyte b = reader.ReadSByte();
        if (b == 0) return 0;
        if (b > 5 && b < 128) return b - 5;
        if (b < -5 && b >= -128) return b + 5;
        
        // Si es un entero largo, requiere lógica de desplazamiento de bits adicional
        return b; 
    }
}