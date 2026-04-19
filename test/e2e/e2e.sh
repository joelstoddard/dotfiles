#!/bin/bash
# End-to-end install/uninstall lifecycle test.
# Asserts uninstall.sh restores the pre-install state for stow-managed paths.

set -euo pipefail

# zshrc adds ~/.local/bin to PATH at shell-init; bare bash needs it explicit.
export PATH="$HOME/.local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAP="$SCRIPT_DIR/snapshot.py"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cd "$REPO_DIR"

echo "=== e2e: capturing pre-install snapshot ==="
python3 "$SNAP" capture "$WORK/pre.json"

echo "=== e2e: running install.sh --skip-packages ==="
./install.sh --yes --skip-packages

echo "=== e2e: running verify.py ==="
.venv/bin/python scripts/verify.py

echo "=== e2e: running uninstall.sh ==="
./uninstall.sh

echo "=== e2e: capturing post-uninstall snapshot ==="
python3 "$SNAP" capture "$WORK/restored.json"

echo "=== e2e: asserting uninstall restored pre-install state ==="
python3 "$SNAP" diff "$WORK/pre.json" "$WORK/restored.json"

echo "=== e2e: PASS ==="
