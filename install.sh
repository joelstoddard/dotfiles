#!/bin/bash
set -euo pipefail

echo "=== Multi-OS Dotfiles Installation ==="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source OS detection
source "$SCRIPT_DIR/os-detect.sh"

echo "Detected environment:"
echo "  OS: $OS"
echo "  Distro: $DISTRO"
echo "  Package Manager: $PKG_MANAGER"
echo "  GUI Available: $HAS_GUI"
echo ""

# Confirm with user
read -p "Continue installation? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Route to OS-specific script
case "$OS" in
    linux)
        case "$DISTRO" in
            debian)
                echo "Running Debian/Ubuntu installation..."
                bash "$SCRIPT_DIR/scripts/debian-ubuntu.sh"
                ;;
            arch)
                echo "Running Arch Linux installation..."
                bash "$SCRIPT_DIR/scripts/arch.sh"
                ;;
            *)
                echo "Error: Unsupported Linux distribution: $DISTRO"
                echo "Supported: Debian, Ubuntu, Arch Linux"
                exit 1
                ;;
        esac
        ;;
    macos)
        echo "Running macOS installation..."
        bash "$SCRIPT_DIR/scripts/macos.sh"
        ;;
    windows)
        echo "Error: Windows is not supported by this dotfiles repository."
        echo ""
        echo "GNU Stow and POSIX shell scripts are incompatible with Windows."
        echo "Consider using a Windows-specific dotfiles solution:"
        echo "  - chezmoi (https://www.chezmoi.io/)"
        echo "  - PowerShell dotfiles with New-Item -ItemType SymbolicLink"
        echo "  - yadm (https://yadm.io/)"
        exit 1
        ;;
    *)
        echo "Error: Unsupported operating system: $OS"
        exit 1
        ;;
esac

# Common post-installation
echo ""
echo "=== Configuring dotfiles with GNU Stow ==="

# Remove conflicting Omarchy configs on Arch
if [[ "$OS" == "linux" && "$DISTRO" == "arch" && -d "$HOME/.config/omarchy" ]]; then
    echo "Removing conflicting Omarchy configuration files..."
    rm -f "$HOME/.config/alacritty/alacritty.toml"
    rm -f "$HOME/.config/git/config"
    rm -rf "$HOME/.config/nvim/"
fi

# Stow all configurations
cd "$SCRIPT_DIR"

# Conditionally ignore rofi on non-Linux or non-GUI systems
if [[ "$OS" != "linux" || "$HAS_GUI" != "yes" ]]; then
    echo "Skipping rofi (Linux GUI-only tool)..."
    echo "^/.config/rofi" >> .stow-local-ignore.tmp
    stow . --adopt -t "$HOME" --ignore=".stow-local-ignore.tmp"
    rm -f .stow-local-ignore.tmp
else
    stow . --adopt -t "$HOME"
fi

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. Verify oh-my-posh prompt displays correctly"
echo "  3. Open a new terminal to test Alacritty configuration"
echo ""
echo "Note: Check TODO.md for remaining manual configuration tasks."
