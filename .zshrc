# Set up the prompt

 Inherit Omarchy Defaults
# . "$HOME/.local/share/../bin/env"

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit snippet OMZP::ansible
# zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::brew
zinit snippet OMZP::command-not-found
# zinit snippet OMZP::debian
zinit snippet OMZP::docker-compose
zinit snippet OMZP::docker
zinit snippet OMZP::eza
zinit snippet OMZP::fzf
zinit snippet OMZP::gh
zinit snippet OMZP::git
zinit snippet OMZP::git.zsh
zinit snippet OMZP::golang
zinit snippet OMZP::gpg-agent
zinit snippet OMZP::helm
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::localstack
# zinit snippet OMZP::macos/music
# zinit snippet OMZP::macos/spotify
# zinit snippet OMZP::macos
zinit snippet OMZP::postgres
zinit snippet OMZP::python
# zinit snippet OMZP::redis-cli
zinit snippet OMZP::rsync
zinit snippet OMZP::ssh
zinit snippet OMZP::sudo
zinit snippet OMZP::systemd
zinit snippet OMZP::tailscale
zinit snippet OMZP::terraform
zinit snippet OMZP::tldr
zinit snippet OMZP::tmux
zinit snippet OMZP::uv

autoload -Uz compinit && compinit
zinit cdreplay -q

# Alias Ctrl+Backspace to Ctrl+W
bindkey '^[[3;5~' backward-kill-word
# Navigate words with Ctrl+Left/Right
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Aliases :(
alias ll='eza -lAh --icons=auto --colo'

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history
HISTDUP=erase

# oh-my-posh configuration
export PATH=$PATH:/home/joel/.local/bin
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.yaml)"
fi

PATH="$PATH:/usr/local/bin/tailscale"

export GPG_TTY=$(tty)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
