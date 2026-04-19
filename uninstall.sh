#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VENV_DIR="$SCRIPT_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Virtual environment not found. Run install.sh first." >&2
    exit 1
fi

exec "$VENV_DIR/bin/python" "$SCRIPT_DIR/scripts/uninstall.py" "$@"
