# Python handler for autoenv.
#
# Contract: _detect / _active / _activate / _deactivate.
# Marker: $PWD/.venv/bin/activate (preferred) then $PWD/venv/bin/activate.
# Current directory only — does not walk up.

_autoenv_python_detect() {
    if [[ -f "$PWD/.venv/bin/activate" ]]; then
        print -r -- "$PWD/.venv"
        return 0
    fi
    if [[ -f "$PWD/venv/bin/activate" ]]; then
        print -r -- "$PWD/venv"
        return 0
    fi
    return 1
}

_autoenv_python_active() {
    print -r -- "${VIRTUAL_ENV:-}"
}

_autoenv_python_activate() {
    source "$1/bin/activate"
}

_autoenv_python_deactivate() {
    if typeset -f deactivate >/dev/null; then
        deactivate
    fi
}
