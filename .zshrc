# Set up the prompt
autoload -Uz promptinit
promptinit

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# oh-my-posh configuration
export PATH=$PATH:/home/joel/.local/bin
eval "$(oh-my-posh init zsh --config /home/joel/.config/oh-my-posh/material-modded.omp.json)"
