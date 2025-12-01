#!/bin/bash

set -eo pipefail

# Remove libreoffice
sudo pacman -Rns --noconfirm libreoffice-fresh libreoffice-still 2>/dev/null

# Install Packages
sudo pacman -S --noconfirm --needed \
wget \
curl \
git \
stow \
zsh \
tmux \
jq \
yq \
net-tools \
grex \
ripgrep \
cmake \
gnupg \
unzip \
firefox \
bitwarden-cli \
bitwarden \
ttf-ibmplex-mono-nerd \
ansible \
aws-cli \
docker \
docker-compose \
go \
gnupg \
helm \
kubectl \
kubectx \
postgresql \
python \
rsync \
tailscale \
terraform \
tldr \
tmux \
uv \

# Install AURs
yay -S --noconfirm --needed \
sipcalc \
ttf-atkinson-hyperlegible-nerd

# Install Oh My Posh
curl -s https://ohmyposh.dev/install.sh | bash -s
export PATH=$PATH:$HOME/.local/bin

# Remove conflicting Omarchy config files
rm ~/.config/alacritty/alacritty.toml ~/.config/git/config
rm -r ~/.config/nvim/

stow . --adopt -t ~
