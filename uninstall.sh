#!/bin/bash

# Remove any .deb packages
sudo rm -f /tmp/*.deb
sudo rm -f /tmp/*.zip

# Remove apt packages
sudo apt purge -y \
firefox \
spotify-client \
zsh \
stow \
rofi \
ddccontrol \
gddccontrol \
ddccontrol-db \
i2c-tools \
nvtop \
fastfetch

# Remove apt repositories and keys

## Firefox
sudo rm /etc/apt/preferences.d/mozilla /etc/apt/sources.list.d/mozilla.list /etc/apt/keyrings/packages.mozilla.org.asc

## Spotify
sudo rm /etc/apt/trusted.gpg.d/spotify.gpg /etc/apt/sources.list.d/spotify.list

# Remove prerequisites
sudo apt purge -y \
wget \
curl \
git \
stow \
zsh \
vim
sudo apt autoremove -y
sudo apt autoclean -y
