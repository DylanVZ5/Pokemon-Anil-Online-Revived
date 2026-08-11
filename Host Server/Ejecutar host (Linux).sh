#!/bin/bash

if ! command -v python3 >/dev/null 2>&1; then
    if command -v pkg >/dev/null 2>&1; then
        pkg install -y python >/dev/null 2>&1
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y python3 >/dev/null 2>&1
    fi
fi

python3 host.py