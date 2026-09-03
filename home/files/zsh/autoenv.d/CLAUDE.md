# autoenv handlers

This directory holds per-language handlers for the `chpwd` auto-activation hook defined in `../autoenv.zsh`. Each `*.zsh` file here is one language.

## The contract

Every handler must define four functions. The function names are derived from the filename: a handler named `python.zsh` must define `_autoenv_python_detect`, `_autoenv_python_active`, `_autoenv_python_activate`, and `_autoenv_python_deactivate`. A handler missing any of the four is skipped at source time with a warning on stderr — it will not break shell startup.

| Function | Input | Returns | Side-effects |
|---|---|---|---|
| `_autoenv_<name>_detect` | reads `$PWD` | echoes an opaque key (any non-empty string) and returns 0 on match; returns non-zero with no output otherwise | none |
| `_autoenv_<name>_active` | none | echoes an opaque key describing the currently-active environment for this language, or empty if none | none |
| `_autoenv_<name>_activate` | `$1` is the key from `_detect` | none | activates the environment |
| `_autoenv_<name>_deactivate` | none | none | tears down whatever `_activate` did |

The dispatcher compares keys as strings. The "key" can be whatever is convenient — an absolute path, a version string, a slug — as long as `_detect` and `_active` agree on the format.

## Discovery

`autoenv.zsh` scans this directory for `*.zsh` files at source time. A file whose basename starts with `_` (e.g. `_nodejs.zsh`) is skipped — use that to disable a handler without deleting it.

## Dispatcher rules

On every `chpwd`, for each handler:

1. **Respect manual activation.** If `_active` reports a non-empty value that doesn't match what this hook activated, skip the handler — don't touch what the user set up themselves.
2. **No-op on match.** If the detected key equals the key we already activated, do nothing.
3. **Tear down before switching.** If we previously activated something different, call `_deactivate` and clear our state.
4. **Activate on detect.** If `_detect` returned a key, call `_activate` with it and record the key.

The hook also runs once when `autoenv.zsh` is first sourced, so the shell's starting directory is evaluated immediately.

## Adding a new language

1. Create `<language>.zsh` in this directory.
2. Define the four functions. Use `python.zsh` as a reference — it's the simplest complete handler.
3. Pick a signal for `_active` that reflects the language's actual tooling. For Python that's `$VIRTUAL_ENV`; for Node you might use `$NVM_BIN` or `$(nvm current)`; for Ruby you might check the output of `rbenv version-name`. The signal must be something the language's tooling sets on activation, not something your handler alone maintains.
4. Add a test scenario to `test/unit/test_autoenv.sh` covering: detection, activate, deactivate, state clears on leave, switch between two projects, and manual activation is respected.
5. Restart your shell (or `source ~/.config/zsh/autoenv.zsh`) to pick up the new handler.

## Skeleton

```zsh
# <language>.zsh — autoenv handler for <language>

_autoenv_<name>_detect() {
    # Inspect $PWD for a marker. Echo a key and return 0 on match.
    # Return non-zero with no output on miss.
    [[ -f "$PWD/<marker>" ]] || return 1
    print -r -- "$PWD/<marker>"
}

_autoenv_<name>_active() {
    # Echo whatever the language's tooling sets when an env is active.
    print -r -- "${SOME_ENV_VAR:-}"
}

_autoenv_<name>_activate() {
    # $1 is the key _detect returned. Activate it.
    :
}

_autoenv_<name>_deactivate() {
    # Undo whatever _activate did. Must be safe to call even if nothing was activated.
    :
}
```

## Things to avoid

- **Don't print on success.** The prompt (oh-my-posh) is responsible for surfacing active environments. Stdout noise on every `cd` is the wrong default. Gate any verbose output on `$AUTOENV_VERBOSE` if you need it.
- **Don't walk up the directory tree.** Detection is intentionally current-dir only — it keeps behaviour predictable and matches the spec.
- **Don't touch state the user owns.** If `_active` returns a value, the dispatcher treats it as the user's — handlers must not second-guess that.
