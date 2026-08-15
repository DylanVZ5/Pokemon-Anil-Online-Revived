#!/bin/bash

echo "========================================"
echo "        Iniciando host.py"
echo "========================================"
echo ""

PYTHON_CMD=""

# ==========================================
# Buscar Python 3 existente
# ==========================================

if command -v python3 >/dev/null 2>&1; then
    if python3 --version >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    fi
fi

# ==========================================
# Si Python no existe, instalarlo
# ==========================================

if [ -z "$PYTHON_CMD" ]; then

    echo "Python 3 is not installed."
    echo "Searching for the latest Python version..."
    echo ""

    # ======================================
    # Termux
    # ======================================

    if command -v pkg >/dev/null 2>&1; then

        echo "Termux detected."
        echo "Installing the latest Python version..."
        echo ""

        pkg update -y

        if [ $? -ne 0 ]; then
            echo "ERROR: Could not update Termux packages."
            exit 1
        fi

        pkg install -y python

        if [ $? -ne 0 ]; then
            echo "ERROR: Could not install Python."
            exit 1
        fi

        PYTHON_CMD="python"

    # ======================================
    # Debian / Ubuntu / derivados
    # ======================================

    elif command -v apt-get >/dev/null 2>&1; then

        echo "Debian/Ubuntu based system detected."
        echo "Updating package information..."
        echo ""

        if command -v sudo >/dev/null 2>&1; then
            sudo apt-get update
        else
            apt-get update
        fi

        if [ $? -ne 0 ]; then
            echo "ERROR: Could not update package information."
            exit 1
        fi

        # Buscar versiones de Python 3 disponibles
        PYTHON_PACKAGE=$(apt-cache search '^python3\.[0-9]+$' 2>/dev/null |
            awk '{print $1}' |
            sort -V |
            tail -n 1)

        # Si no encontro una version especifica, usar python3
        if [ -z "$PYTHON_PACKAGE" ]; then
            PYTHON_PACKAGE="python3"
        fi

        echo "Latest Python package found: $PYTHON_PACKAGE"
        echo ""

        if command -v sudo >/dev/null 2>&1; then
            sudo apt-get install -y "$PYTHON_PACKAGE"
        else
            apt-get install -y "$PYTHON_PACKAGE"
        fi

        if [ $? -ne 0 ]; then
            echo "ERROR: Could not install Python."
            exit 1
        fi

        # Determinar comando
        if command -v python3 >/dev/null 2>&1; then
            PYTHON_CMD="python3"
        elif command -v "$PYTHON_PACKAGE" >/dev/null 2>&1; then
            PYTHON_CMD="$PYTHON_PACKAGE"
        fi

    else

        echo "ERROR: No compatible package manager was found."
        echo "This script supports:"
        echo "- Termux"
        echo "- Debian"
        echo "- Ubuntu"
        echo "- Debian/Ubuntu based systems"
        exit 1

    fi

    # ======================================
    # Comprobar Python despues de instalar
    # ======================================

    if [ -z "$PYTHON_CMD" ]; then

        if command -v python3 >/dev/null 2>&1; then
            PYTHON_CMD="python3"
        elif command -v python >/dev/null 2>&1; then
            PYTHON_CMD="python"
        fi

    fi

    if [ -z "$PYTHON_CMD" ]; then
        echo ""
        echo "ERROR: Python was installed but could not be found."
        echo "Restart the terminal and try again."
        exit 1
    fi

fi

# ==========================================
# Mostrar version encontrada
# ==========================================

echo "Python found:"
$PYTHON_CMD --version

echo ""

# ==========================================
# Comprobar host.py
# ==========================================

if [ ! -f "host.py" ]; then
    echo "ERROR: host.py was not found."
    echo "Make sure host.py is in the same folder as this script."
    exit 1
fi

# ==========================================
# Ejecutar host.py
# ==========================================

echo "Running host.py..."
echo ""

$PYTHON_CMD host.py

EXIT_CODE=$?

echo ""
echo "host.py finished with code: $EXIT_CODE"