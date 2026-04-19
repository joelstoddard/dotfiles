# ~/.config/zsh/autoenv.zsh
#
# On chpwd, dispatch to per-language handlers under autoenv.d/. Each handler
# follows a four-function contract (_detect / _active / _activate / _deactivate).
# State in _AUTOENV_ACTIVE lets the hook tear down only what it itself activated.

autoload -Uz add-zsh-hook

typeset -gA _AUTOENV_ACTIVE
typeset -ga _AUTOENV_HANDLERS
# Reset on each source; handler discovery below repopulates this list.
_AUTOENV_HANDLERS=()

# Discover and source handler files from autoenv.d/ next to this script.
# Files whose basename starts with `_` are skipped (convention for disabling).
() {
    local self_dir="${${(%):-%x}:A:h}"
    local handler_dir="$self_dir/autoenv.d"
    [[ -d $handler_dir ]] || return 0
    local f name
    for f in $handler_dir/*.zsh(N); do
        name=${f:t:r}
        [[ $name == _* ]] && continue
        source "$f"
        _AUTOENV_HANDLERS+=("$name")
    done
}

_autoenv_chpwd() {
    [[ -n "${AUTOENV_DISABLE:-}" ]] && return 0
    return 0
}

add-zsh-hook chpwd _autoenv_chpwd
