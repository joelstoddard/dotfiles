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
    local h wanted owned external
    for h in $_AUTOENV_HANDLERS; do
        wanted=$(_autoenv_${h}_detect 2>/dev/null) || wanted=
        owned=${_AUTOENV_ACTIVE[$h]-}
        external=$(_autoenv_${h}_active 2>/dev/null)
        # Respect manual activation: if something is active that we didn't set, stay out.
        if [[ -n $external && $external != $owned ]]; then
            continue
        fi
        if [[ $wanted == $owned ]]; then
            continue
        fi
        if [[ -n $owned ]]; then
            "_autoenv_${h}_deactivate"
            unset "_AUTOENV_ACTIVE[$h]"
        fi
        if [[ -n $wanted ]]; then
            "_autoenv_${h}_activate" "$wanted"
            _AUTOENV_ACTIVE[$h]=$wanted
        fi
    done
    return 0
}

add-zsh-hook chpwd _autoenv_chpwd
