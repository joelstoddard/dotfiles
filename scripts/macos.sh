#!/bin/bash
set -euo pipefail

echo "=== macOS Package Installation ==="

# Check for Homebrew, install if needed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Set up Homebrew in current shell
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Update Homebrew
echo "Updating Homebrew..."
brew update

# Install CLI tools
echo "Installing CLI tools..."
brew install \
    wget \
    curl \
    git \
    stow \
    zsh \
    tmux \
    jq \
    yq \
    ripgrep \
    grex \
    cmake \
    gnupg \
    unzip \
    ansible \
    awscli \
    go \
    helm \
    kubectl \
    kubectx \
    postgresql@16 \
    python@3.12 \
    rsync \
    terraform \
    tldr \
    sipcalc \
    bitwarden-cli \
    fzf

# Install cask applications
echo "Installing GUI applications..."
brew install --cask \
    firefox \
    bitwarden \
    alacritty \
    docker

# Install Nerd Fonts
echo "Installing Nerd Fonts..."
brew tap homebrew/cask-fonts
brew install --cask \
    font-ibm-plex-mono-nerd-font \
    font-atkinson-hyperlegible-nerd-font

# Install Oh My Posh
echo "Installing Oh My Posh..."
if ! command -v oh-my-posh &> /dev/null; then
    brew install jandedobbeleer/oh-my-posh/oh-my-posh
fi

# Install NVM for Node.js
echo "Installing NVM and Node.js..."
if [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 24
else
    echo "NVM already installed"
fi

# Install Rust toolchain
echo "Installing Rust..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust already installed"
fi

# Change default shell to zsh
if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo "Setting zsh as default shell..."
    sudo chsh -s "$(which zsh)" "$USER"
    echo "Shell changed. You may need to log out and back in for this to take effect."
fi

echo "macOS package installation complete!"
