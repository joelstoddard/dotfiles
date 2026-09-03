#!/usr/bin/env python3
"""Remove dotfile symlinks by running stow -D."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scripts.lib import stow

REPO_DIR = Path(__file__).resolve().parent.parent


def remove_claude_settings_symlink(home: Path | None = None) -> None:
    """Remove the settings.json link install.py created outside stow's control.

    Leaves anything else in place, including a real file a user put there.
    """
    target = REPO_DIR / ".claude" / "user-settings.json"
    link = (home or Path.home()) / ".claude" / "settings.json"

    if link.is_symlink() and link.resolve() == target.resolve():
        link.unlink()
        print("  Claude settings.json link removed.")


def main() -> None:
    print("=== dotfiles uninstaller ===\n")

    try:
        stow.remove(REPO_DIR)
        remove_claude_settings_symlink()
        print("Symlinks removed successfully.")
        print("Installed packages are untouched.")
    except Exception as e:
        print(f"Error removing symlinks: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
