#!/usr/bin/env python3
"""Remove dotfile symlinks by running stow -D."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scripts.lib import stow

REPO_DIR = Path(__file__).resolve().parent.parent


def main() -> None:
    print("=== dotfiles uninstaller ===\n")

    try:
        stow.remove(REPO_DIR)
        print("Symlinks removed successfully.")
        print("Installed packages are untouched.")
    except Exception as e:
        print(f"Error removing symlinks: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
