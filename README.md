# 🌐 Pokémon Añil - Online Fix & Dedicated Server

Este proyecto incluye la versión de **Pokémon Añil** con el modo multijugador (Cable Club) completamente reparado y estabilizado, además de un servidor dedicado (Host) optimizado en Python. **El juego ya viene completamente modificado y listo para jugar, no requiere ningún tipo de parcheo o instalación de scripts.**

## ✨ Características Principales

* **Servidor Asíncrono Estable:** Un host ultraligero que evita los cuellos de botella y los bloqueos de pantalla en "Esperando..." durante la transferencia de datos.
* **Bloqueo Anti-Desync (Turbo Fix):** Desactiva automáticamente el "Fast Forward" de los jugadores durante los combates online y fuerza la velocidad a x2, evitando desincronizaciones críticas de red.
* **Sistema de Backup Automático:** Antes de iniciar cualquier conexión en el Cable Club, el juego realiza una copia de seguridad automática de tu partida en la carpeta `Saves Backup` para proteger tu progreso.
* **Cláusula de Velocidad Personalizable:** Un nuevo menú inyectado en las reglas de combate que permite al creador de la sala elegir la velocidad de la partida (x1 o x2) antes de empezar.

## 🚀 Cómo Levantar el Servidor (Host)

Para que los jugadores puedan conectarse entre sí, una persona debe mantener abierto el servidor. Todos los archivos necesarios para esto se encuentran dentro de la carpeta **`Host Server`**.

### 💻 Opción A: Hostear en Windows
1. Entra a la carpeta `Host Server`.
2. Haz clic derecho sobre el archivo `iniciar_servidor.ps1` y selecciona **"Ejecutar con PowerShell"**.
3. *Nota:* Si tu PC no tiene Python instalado, el script lo descargará e instalará automáticamente en segundo plano antes de arrancar.

### 📱 Opción B: Hostear en Android (vía Termux)
Puedes hostear la partida directamente desde tu dispositivo móvil, lo cual es ideal para mantener el servidor corriendo de forma ligera en tu Redmi 10C (o cualquier terminal Android) sin depender de una computadora:
1. Descarga e instala la aplicación **Termux** en tu dispositivo Android.
2. Pasa la carpeta `Host Server` a la memoria interna de tu teléfono.
3. Abre Termux y navega hasta la carpeta usando el comando `cd` (ejemplo: `cd /storage/emulated/0/Ruta/A/Tu/Carpeta/Host\ Server`).
4. La primera vez que lo uses, otórgale permisos de ejecución al script escribiendo:
   `chmod +x iniciar_servidor.sh`
5. Ejecuta el servidor con el siguiente comando:
   `./iniciar_servidor.sh`
*(El script detectará si a tu Termux le falta Python y lo instalará automáticamente de forma silenciosa).*

## 🏆 Créditos

* **Eric Lostie**: Creador de Pokémon Añil y desarrollador principal del fangame.
* **Skyflyer**: Colaborador y desarrollador de Pokémon Añil.
* **DPertierra**: Colaborador y desarrollador de Pokémon Añil.
* **Nylox**: Agradecimiento especial por colaborar con las bases fundamentales para arreglar la arquitectura del modo online.
* **DylanVZ5**: Modificaciones del código fuente (Ruby), mejoras de QoL (Calidad de vida), desarrollo del servidor puente asíncrono en Python.