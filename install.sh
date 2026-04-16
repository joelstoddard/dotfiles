#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Bootstrap Python 3
if ! command -v python3 &>/dev/null; then
    echo "Python 3 not found. Installing..."
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y python3 python3-pip python3-venv
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm python python-pip
    elif command -v brew &>/dev/null; then
        brew install python
    else
        echo "Error: Cannot install Python 3. Install it manually." >&2
        exit 1
    fi
fi

# Set up virtual environment and install dependencies
VENV_DIR="$SCRIPT_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/pip" install --quiet pyyaml 2>/dev/null

exec "$VENV_DIR/bin/python" "$SCRIPT_DIR/scripts/install.py" "$@"
