# ============================================================================
# Environment
# ============================================================================
typeset -U path

# Omarchy defaults (Arch Linux)
if [[ ! -f "/opt/homebrew/bin/brew" ]] && [[ -f "$HOME/.local/share/../bin/env" ]]; then
    . "$HOME/.local/share/../bin/env"
fi

# Homebrew (macOS)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Cargo
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)

# Local bin
path=("$HOME/.local/bin" $path)

# ============================================================================
# Completions
# ============================================================================
ZSH_PLUGINS="$HOME/.local/share/zsh/plugins"

# zsh-completions
[[ -d "$ZSH_PLUGINS/zsh-completions/src" ]] && fpath=("$ZSH_PLUGINS/zsh-completions/src" $fpath)

# zsh-autosuggestions
[[ -f "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Generated tool completions
[[ -d "$HOME/.local/share/zsh/completions" ]] && fpath=("$HOME/.local/share/zsh/completions" $fpath)

# Docker completions
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

autoload -Uz compinit && compinit
# Suppress insecure directory warnings
compinit -u 2>/dev/null

# ============================================================================
# Key Bindings
# ============================================================================
bindkey '^[[3;5~' backward-kill-word     # Ctrl+Backspace
bindkey '^[[1;5D' backward-word          # Ctrl+Left
bindkey '^[[1;5C' forward-word           # Ctrl+Right

# ============================================================================
# History
# ============================================================================
HISTSIZE=1000
SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# ============================================================================
# Aliases
# ============================================================================
if command -v eza &>/dev/null; then
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lsa='ls -a'
    alias lt='eza --tree --level=2 --long --icons --git'
    alias lta='lt -a'
fi

# ============================================================================
# Tool Init
# ============================================================================

# oh-my-posh
if command -v oh-my-posh &>/dev/null && [[ "$TERM_PROGRAM" != "Apple_Terminal" ]]; then
    eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.yaml)"
fi

# GPG
export GPG_TTY=$(tty)

# NVM (lazy loaded — only sources when nvm/node/npm/npx is first called)
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    _lazy_nvm() {
        unfunction nvm node npm npx 2>/dev/null
        . "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
    }
    nvm()  { _lazy_nvm; nvm  "$@" }
    node() { _lazy_nvm; node "$@" }
    npm()  { _lazy_nvm; npm  "$@" }
    npx()  { _lazy_nvm; npx  "$@" }
fi

# PostgreSQL client (macOS)
if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/opt/homebrew/opt/libpq@16/bin" ]]; then
    path=("/opt/homebrew/opt/libpq@16/bin" $path)
fi

# JFrog CLI completion
if command -v jfrog &>/dev/null; then
    _jfrog() {
        local -a opts
        opts=("${(@f)$(_CLI_ZSH_AUTOCOMPLETE_HACK=1 ${words[@]:0:#words[@]-1} --generate-bash-completion)}")
        _describe 'values' opts
        if [[ $compstate[nmatches] -eq 0 && $words[$CURRENT] != -* ]]; then
            _files
        fi
    }
    compdef _jfrog jfrog
    compdef _jfrog jf
fi

# ZSH tmux plugin compat
export ZSH_TMUX_FIXTERM=false

# ============================================================================
# Shell Integrations
# ============================================================================

# fzf key bindings (Ctrl-R history, Ctrl-T files, Alt-C cd) + completion
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi

# command-not-found — suggest installable packages when a command is missing
# Debian/Ubuntu ship /etc/zsh_command_not_found; Arch provides it via pkgfile
for f in /etc/zsh_command_not_found /usr/share/doc/pkgfile/command-not-found.zsh; do
    [[ -r "$f" ]] && source "$f" && break
done

# AWS CLI tab completion via the official aws_completer (bash-style, needs bashcompinit)
if command -v aws_completer &>/dev/null; then
    autoload -U +X bashcompinit && bashcompinit
    complete -C "$(command -v aws_completer)" aws
fi

# List configured AWS profiles (helper function, not an alias)
aws_profiles() {
    grep -h -Eo '\[(profile[[:space:]]+)?[^]]+\]' \
        "${AWS_CONFIG_FILE:-$HOME/.aws/config}" \
        "${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}" 2>/dev/null \
        | sed -E 's/^\[(profile[[:space:]]+)?//; s/\]$//' \
        | grep -v '^granted_registry_' \
        | sort -u
}

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform
