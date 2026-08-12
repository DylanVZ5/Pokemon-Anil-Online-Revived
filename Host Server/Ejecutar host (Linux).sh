#!/bin/bash

# Comprobar si Python 3 está instalado
if ! command -v python3 >/dev/null 2>&1; then
    echo "Python 3 no está instalado. Instalando..."

    # Termux
    if command -v pkg >/dev/null 2>&1; then
        pkg install -y python

        if [ $? -ne 0 ]; then
            echo "ERROR: No se pudo instalar Python mediante pkg."
            exit 1
        fi

    # Debian / Ubuntu y derivados
    elif command -v apt-get >/dev/null 2>&1; then
        if command -v sudo >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y python3
        else
            apt-get update
            apt-get install -y python3
        fi

        if [ $? -ne 0 ]; then
            echo "ERROR: No se pudo instalar Python mediante apt-get."
            exit 1
        fi

    else
        echo "ERROR: No se encontró un gestor de paquetes compatible."
        echo "Este script soporta Termux (pkg) y Debian/Ubuntu (apt-get)."
        exit 1
    fi

    # Comprobar nuevamente después de la instalación
    if ! command -v python3 >/dev/null 2>&1; then
        echo "ERROR: Python se instaló, pero no se encontró en el PATH."
        echo "Reinicia la terminal e inténtalo nuevamente."
        exit 1
    fi
fi

# Comprobar que host.py existe
if [ ! -f "host.py" ]; then
    echo "ERROR: No se encontró host.py en la carpeta actual."
    exit 1
fi

echo "Python 3 encontrado."
echo "Ejecutando host.py..."

python3 host.py