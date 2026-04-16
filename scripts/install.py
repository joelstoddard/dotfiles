#!/usr/bin/env python3
"""Main dotfiles installer.

Reads packages.yaml, installs packages for the detected OS,
sets up shell plugins, generates theme files, and applies stow.
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

# Ensure scripts/ is importable
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scripts.lib.os_detect import detect
from scripts.lib.packages import load, resolve, install_all
from scripts.lib import stow


REPO_DIR = Path(__file__).resolve().parent.parent
PACKAGES_YAML = REPO_DIR / "packages" / "packages.yaml"

# Categories included without --gui
CLI_CATEGORIES = {"core", "development", "work"}

# Additional categories included with --gui
GUI_CATEGORIES = {"desktop", "gaming", "3d-modelling", "streaming-video-production"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Install dotfiles and packages.")
    parser.add_argument(
        "--gui", action="store_true",
        help="Include desktop/GUI packages (default: CLI-only)",
    )
    parser.add_argument(
        "--include", type=str, default=None,
        help="Comma-separated list of categories to install (overrides defaults)",
    )
    parser.add_argument(
        "--exclude", type=str, default=None,
        help="Comma-separated list of categories to exclude",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Show what would be installed without actually installing",
    )
    parser.add_argument(
        "--yes", "-y", action="store_true",
        help="Skip confirmation prompt",
    )
    parser.add_argument(
        "--skip-packages", action="store_true",
        help="Skip package installation (only stow configs)",
    )
    parser.add_argument(
        "--skip-stow", action="store_true",
        help="Skip stow (only install packages)",
    )
    return parser.parse_args()


def confirm(message: str) -> bool:
    """Prompt user for yes/no confirmation."""
    try:
        response = input(f"{message} [y/N] ").strip().lower()
        return response in ("y", "yes")
    except (EOFError, KeyboardInterrupt):
        print()
        return False


def setup_zsh_plugins() -> None:
    """Clone zsh-completions and zsh-autosuggestions if not present."""
    plugin_dir = Path.home() / ".local" / "share" / "zsh" / "plugins"
    plugin_dir.mkdir(parents=True, exist_ok=True)

    plugins = {
        "zsh-completions": "https://github.com/zsh-users/zsh-completions.git",
        "zsh-autosuggestions": "https://github.com/zsh-users/zsh-autosuggestions.git",
    }

    for name, url in plugins.items():
        dest = plugin_dir / name
        if dest.exists():
            print(f"  [ok] {name} (already cloned)")
        else:
            print(f"  [clone] {name}...")
            subprocess.run(["git", "clone", "--depth=1", url, str(dest)], check=True)


def setup_completions_dir() -> None:
    """Create the completions directory for generated completions."""
    completions_dir = Path.home() / ".local" / "share" / "zsh" / "completions"
    completions_dir.mkdir(parents=True, exist_ok=True)


def setup_alacritty_os_symlink(platform) -> None:
    """Create the os.toml symlink for Alacritty based on platform."""
    alacritty_dir = Path.home() / ".config" / "alacritty"
    os_toml = alacritty_dir / "os.toml"

    if platform.os == "macos":
        target = "macos.toml"
    elif platform.distro == "arch":
        target = "arch.toml"
    else:
        target = "linux.toml"

    if os_toml.is_symlink():
        os_toml.unlink()
    elif os_toml.exists():
        os_toml.unlink()

    os_toml.symlink_to(target)
    print(f"  Alacritty os.toml -> {target}")


def remove_omarchy_conflicts() -> None:
    """Remove conflicting Omarchy config files before stowing."""
    home = Path.home()
    conflicts = [
        home / ".config" / "alacritty" / "alacritty.toml",
        home / ".config" / "git" / "config",
        home / ".config" / "nvim",
    ]
    for path in conflicts:
        if path.exists() and not path.is_symlink():
            print(f"  Removing conflicting Omarchy config: {path}")
            if path.is_dir():
                import shutil
                shutil.rmtree(path)
            else:
                path.unlink()


def setup_tpm() -> None:
    """Install Tmux Plugin Manager if not present."""
    tpm_dir = Path.home() / ".config" / "tmux" / "plugins" / "tpm"
    if tpm_dir.exists():
        print("  [ok] TPM (already installed)")
    else:
        print("  [clone] TPM...")
        subprocess.run(
            ["git", "clone", "--depth=1",
             "https://github.com/tmux-plugins/tpm", str(tpm_dir)],
            check=True,
        )
        print("  Run 'prefix + I' in tmux to install plugins.")


def generate_theme() -> None:
    """Run the theme generator."""
    script = REPO_DIR / "scripts" / "generate_theme.py"
    if script.exists():
        subprocess.run([sys.executable, str(script)], check=True)


def generate_completions() -> None:
    """Run the completions generator."""
    script = REPO_DIR / "scripts" / "generate_completions.py"
    if script.exists():
        subprocess.run([sys.executable, str(script)], check=True)


def main() -> int:
    args = parse_args()
    failed_count = 0

    print("=== dotfiles-v2 installer ===\n")

    # Detect platform
    platform = detect()
    print(f"Detected: {platform}\n")

    # Determine categories
    if args.include:
        selected = args.include.split(",")
    else:
        selected = list(CLI_CATEGORIES)
        if args.gui:
            selected.extend(GUI_CATEGORIES)

    excluded = args.exclude.split(",") if args.exclude else []

    effective = [c for c in selected if c not in excluded]
    print(f"Categories: {', '.join(effective)}")
    if not args.gui and not args.include:
        print("(Use --gui to include desktop/gaming packages)\n")

    if not args.yes and not args.dry_run:
        if not confirm("\nContinue with installation?"):
            print("Cancelled.")
            return 0

    # Install packages
    if not args.skip_packages:
        print("\n=== Installing packages ===")
        data = load(PACKAGES_YAML)
        categories = resolve(data, platform)
        result = install_all(
            categories, platform,
            selected=selected, excluded=excluded,
            dry_run=args.dry_run,
        )
        print(f"\n{result.summary()}")

        if result.failed and not args.dry_run:
            failed_count = len(result.failed)
            print("\nSome packages failed to install. Continuing with config setup...")

    if args.dry_run:
        print("\n[dry-run] Skipping config setup.")
        return 0

    # Post-install setup
    if not args.skip_stow:
        print("\n=== Setting up shell plugins ===")
        setup_zsh_plugins()
        setup_completions_dir()

        print("\n=== Generating completions ===")
        generate_completions()

        print("\n=== Generating theme ===")
        generate_theme()

        # Handle Omarchy conflicts
        if platform.distro == "arch":
            omarchy_dir = Path.home() / ".config" / "omarchy"
            if omarchy_dir.exists():
                print("\n=== Removing Omarchy conflicts ===")
                remove_omarchy_conflicts()

        print("\n=== Applying stow ===")
        stow.apply(REPO_DIR)
        print("  Configs symlinked to $HOME")

        # Alacritty os.toml
        alacritty_dir = Path.home() / ".config" / "alacritty"
        if alacritty_dir.exists():
            print("\n=== Configuring Alacritty ===")
            setup_alacritty_os_symlink(platform)

        # TPM
        print("\n=== Setting up tmux ===")
        setup_tpm()

    print("\n=== Installation complete! ===")
    print()
    print("Next steps:")
    print("  1. Restart your shell or run: source ~/.zshrc")
    print("  2. Verify oh-my-posh prompt displays correctly")
    print("  3. In tmux, press prefix + I to install plugins")
    if args.gui:
        print("  4. Open Alacritty to verify terminal config")

    return 1 if failed_count else 0


if __name__ == "__main__":
    sys.exit(main())
