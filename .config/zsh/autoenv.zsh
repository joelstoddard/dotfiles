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

_autoenv_chpwd() {
    [[ -n "${AUTOENV_DISABLE:-}" ]] && return 0
    return 0
}

add-zsh-hook chpwd _autoenv_chpwd
