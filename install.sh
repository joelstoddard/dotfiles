#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate a Python interpreter that supports the features used by scripts/ (match statements → 3.10+)
# AND has the stdlib modules venv creation needs. We validate rather than trust, because a broken
# brew bottle (e.g. pyexpat linked against a too-old system libexpat) can leave `python3` importable
# but unable to `-m venv`.
PYTHON_BIN=""
for candidate in python3.13 python3.12 python3.11 python3.10 python3.14 python3; do
    if command -v "$candidate" &>/dev/null; then
        if "$candidate" -c 'import sys, ensurepip, pyexpat; sys.exit(0 if sys.version_info >= (3, 10) else 1)' &>/dev/null; then
            PYTHON_BIN="$(command -v "$candidate")"
            break
        fi
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo "Python >= 3.10 not found. Installing..."
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y python3 python3-pip python3-venv
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm python python-pip
    elif command -v brew &>/dev/null; then
        brew install python3
    else
        echo "Error: Cannot install Python >= 3.10. Install it manually." >&2
        exit 1
    fi
    PYTHON_BIN="$(command -v python3)"
fi

# Set up virtual environment and install dependencies
VENV_DIR="$SCRIPT_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment with $PYTHON_BIN..."
    "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/pip" install --quiet pyyaml 2>/dev/null

exec "$VENV_DIR/bin/python" "$SCRIPT_DIR/scripts/install.py" "$@"
