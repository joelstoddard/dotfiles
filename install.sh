#!/bin/bash

# Remove libreoffice
sudo apt purge -y libreoffice* && \
sudo apt autoremove -y
sudo apt autoclean -y

# Install prerequisites
sudo apt update && \
sudo apt upgrade -y && \
sudo apt install -y \
wget \
curl \
git \
stow \
zsh \
vim \
jq \
yq

# Configure apt repositories

## Firefox
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla

## Spotify
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# Install Apt Packages
sudo apt update && \
sudo apt install -y \
firefox \
spotify-client \
obs-studio \
zsh \
stow \
rofi \
ddccontrol \
gddccontrol \
ddccontrol-db \
i2c-tools \
nvtop \
fastfetch \
btop \
sipcalc

# Install .deb Packages

## Bitwarden
wget -q https://github.com/bitwarden/clients/releases/download/desktop-v2025.5.1/Bitwarden-2025.5.1-amd64.deb -O /tmp/bitwarden.deb
sudo dpkg -i /tmp/bitwarden.deb
rm /tmp/bitwarden.deb

## Bitwarden CLI
wget -q https://github.com/bitwarden/clients/releases/download/cli-v2025.5.0/bw-linux-2025.5.0.zip -O /tmp/bitwarden-cli.zip
sudo unzip -o -q /tmp/bitwarden-cli.zip -d /usr/local/bin
rm /tmp/bitwarden-cli.zip

## Discord
wget -q https://stable.dl2.discordapp.net/apps/linux/0.0.96/discord-0.0.96.deb -O /tmp/discord.deb
sudo dpkg -i /tmp/discord.deb
rm /tmp/discord.deb

## Lotion (Notion desktop client)
wget -q https://github.com/puneetsl/lotion/releases/download/v1.0.0/lotion_1.0.0_amd64.deb -O /tmp/lotion.deb
sudo dpkg -i /tmp/lotion.deb
rm /tmp/lotion.deb

## VSCode
wget -q https://vscode.download.prss.microsoft.com/dbazure/download/stable/258e40fedc6cb8edf399a463ce3a9d32e7e1f6f3/code_1.100.3-1748872405_amd64.deb -O /tmp/vscode.deb
sudo dpkg -i /tmp/vscode.deb
rm /tmp/vscode.deb

# Install Oh My Posh
curl -s https://ohmyposh.dev/install.sh | bash -s
