"""GNU Stow wrapper for applying and removing dotfile symlinks."""

import subprocess
from pathlib import Path


def apply(repo_dir: Path, target: Path | None = None) -> None:
    """Apply stow from repo_dir to target (default: $HOME)."""
    target = target or Path.home()
    subprocess.run(
        ["stow", ".", "--adopt", "-t", str(target)],
        cwd=repo_dir,
        check=True,
    )


def remove(repo_dir: Path, target: Path | None = None) -> None:
    """Remove stow symlinks."""
    target = target or Path.home()
    subprocess.run(
        ["stow", "-D", ".", "-t", str(target)],
        cwd=repo_dir,
        check=True,
    )
