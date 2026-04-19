#!/bin/bash
# End-to-end lifecycle test.
#
# Verifies:
#   1. install.sh produces symlinks that pass verify.py
#   2. uninstall.sh restores the pre-install state (stow-managed paths only)
#
# Expects $HOME to be empty of stow-managed config files at start.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAP="$SCRIPT_DIR/snapshot.py"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Everything stow does not manage (venv, zsh plugins in ~/.local, os.toml, tpm)
# is filtered at the source via .stow-local-ignore — the snapshot tool walks
# the repo for its path list, so install artifacts outside that tree never
# appear in a snapshot. No extra exclusions needed here.
EXCLUDE=""

echo "=== e2e: capturing pre-install snapshot ==="
python3 "$SNAP" capture "$WORK/pre.json"

echo "=== e2e: running install.sh --skip-packages ==="
cd "$REPO_DIR"
./install.sh --yes --skip-packages

echo "=== e2e: capturing post-install snapshot ==="
python3 "$SNAP" capture "$WORK/post.json"

echo "=== e2e: asserting install changed the state ==="
if python3 "$SNAP" diff "$WORK/pre.json" "$WORK/post.json" --exclude "$EXCLUDE" > /dev/null; then
    echo "FAIL: install.sh made no changes to stow-managed paths"
    exit 1
fi

echo "=== e2e: running verify.py ==="
.venv/bin/python scripts/verify.py

echo "=== e2e: running uninstall.sh ==="
./uninstall.sh

echo "=== e2e: capturing post-uninstall snapshot ==="
python3 "$SNAP" capture "$WORK/restored.json"

echo "=== e2e: asserting uninstall restored pre-install state ==="
python3 "$SNAP" diff "$WORK/pre.json" "$WORK/restored.json" --exclude "$EXCLUDE"

echo "=== e2e: PASS ==="
