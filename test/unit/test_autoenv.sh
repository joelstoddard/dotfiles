#!/usr/bin/env zsh
# Shell unit tests for .config/zsh/autoenv.zsh.
#
# Structure: each test is a function that returns 0 on success or calls
# `die <msg>` to fail. run_test executes the function in a subshell so
# cd, hook registrations, and env mutations don't leak between tests.

set -u

typeset REPO_ROOT="${${(%):-%x}:A:h:h:h}"
typeset AUTOENV_SCRIPT="$REPO_ROOT/.config/zsh/autoenv.zsh"

typeset -i PASSED=0 FAILED=0

die() {
    print -u2 "    $1"
    exit 1
}

run_test() {
    local name=$1 fn=$2
    print -- "--- $name"
    if ( "$fn" ); then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
}

# make_fake_venv <dir>
#   Creates <dir>/bin/activate as a minimal shell script that sets
#   $VIRTUAL_ENV and defines a `deactivate` function, so tests don't need
#   real Python.
make_fake_venv() {
    local venv=$1
    mkdir -p "$venv/bin"
    cat >"$venv/bin/activate" <<'EOF'
# Fake activate — zsh only. Used exclusively by test/unit/test_autoenv.sh.
export VIRTUAL_ENV="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
deactivate() {
    unset VIRTUAL_ENV
    unfunction deactivate
}
EOF
}

# === test cases (added by subsequent tasks) ===

test_source_succeeds() {
    source "$AUTOENV_SCRIPT" || die "source returned non-zero"
}

test_state_array_declared() {
    source "$AUTOENV_SCRIPT"
    [[ ${(t)_AUTOENV_ACTIVE} == *association* ]] || die "_AUTOENV_ACTIVE is not an assoc array"
}

test_chpwd_hook_registered() {
    source "$AUTOENV_SCRIPT"
    [[ " ${chpwd_functions[*]} " == *" _autoenv_chpwd "* ]] \
        || die "_autoenv_chpwd not in chpwd_functions (got: ${chpwd_functions[*]})"
}

test_autoenv_disable_short_circuits() {
    AUTOENV_DISABLE=1
    source "$AUTOENV_SCRIPT"
    _autoenv_chpwd || die "dispatcher returned non-zero when disabled"
}

run_test "source succeeds"                test_source_succeeds
run_test "state array declared"           test_state_array_declared
run_test "chpwd hook registered"          test_chpwd_hook_registered
run_test "AUTOENV_DISABLE short-circuits" test_autoenv_disable_short_circuits

test_python_detect_finds_dotvenv() {
    local tmp=$(mktemp -d)
    make_fake_venv "$tmp/.venv"
    source "$REPO_ROOT/.config/zsh/autoenv.d/python.zsh"
    cd "$tmp"
    local key=$(_autoenv_python_detect)
    [[ $key == "$tmp/.venv" ]] || die "expected $tmp/.venv, got '$key'"
    rm -rf "$tmp"
}

test_python_detect_finds_venv_fallback() {
    local tmp=$(mktemp -d)
    make_fake_venv "$tmp/venv"
    source "$REPO_ROOT/.config/zsh/autoenv.d/python.zsh"
    cd "$tmp"
    local key=$(_autoenv_python_detect)
    [[ $key == "$tmp/venv" ]] || die "expected $tmp/venv, got '$key'"
    rm -rf "$tmp"
}

test_python_detect_prefers_dotvenv() {
    local tmp=$(mktemp -d)
    make_fake_venv "$tmp/.venv"
    make_fake_venv "$tmp/venv"
    source "$REPO_ROOT/.config/zsh/autoenv.d/python.zsh"
    cd "$tmp"
    local key=$(_autoenv_python_detect)
    [[ $key == "$tmp/.venv" ]] || die ".venv should win when both present, got '$key'"
    rm -rf "$tmp"
}

test_python_detect_returns_nonzero_when_absent() {
    local tmp=$(mktemp -d)
    source "$REPO_ROOT/.config/zsh/autoenv.d/python.zsh"
    cd "$tmp"
    local out
    out=$(_autoenv_python_detect) && die "expected non-zero return, got 0 with output '$out'"
    [[ -z $out ]] || die "expected no output on miss, got '$out'"
    rm -rf "$tmp"
}

test_python_active_reads_virtualenv() {
    source "$REPO_ROOT/.config/zsh/autoenv.d/python.zsh"
    VIRTUAL_ENV=/some/path
    [[ $(_autoenv_python_active) == /some/path ]] || die "active should echo VIRTUAL_ENV"
    unset VIRTUAL_ENV
    [[ -z $(_autoenv_python_active) ]] || die "active should be empty when VIRTUAL_ENV unset"
}

test_python_activate_sources_activate_script() {
    local tmp=$(mktemp -d)
    make_fake_venv "$tmp/.venv"
    source "$REPO_ROOT/.config/zsh/autoenv.d/python.zsh"
    _autoenv_python_activate "$tmp/.venv"
    [[ ${VIRTUAL_ENV:-} == "$tmp/.venv" ]] || die "VIRTUAL_ENV should be $tmp/.venv, got '${VIRTUAL_ENV:-}'"
    typeset -f deactivate >/dev/null || die "deactivate function not defined after activate"
    rm -rf "$tmp"
}

test_python_deactivate_calls_deactivate() {
    local tmp=$(mktemp -d)
    make_fake_venv "$tmp/.venv"
    source "$REPO_ROOT/.config/zsh/autoenv.d/python.zsh"
    _autoenv_python_activate "$tmp/.venv"
    _autoenv_python_deactivate
    [[ -z ${VIRTUAL_ENV:-} ]] || die "VIRTUAL_ENV still set after deactivate"
    rm -rf "$tmp"
}

test_python_deactivate_is_safe_when_no_deactivate_defined() {
    source "$REPO_ROOT/.config/zsh/autoenv.d/python.zsh"
    _autoenv_python_deactivate || die "deactivate should be safe no-op when nothing active"
}

run_test "python detect: .venv"                   test_python_detect_finds_dotvenv
run_test "python detect: venv fallback"           test_python_detect_finds_venv_fallback
run_test "python detect: .venv wins over venv"    test_python_detect_prefers_dotvenv
run_test "python detect: absent returns nonzero"  test_python_detect_returns_nonzero_when_absent
run_test "python active reads VIRTUAL_ENV"        test_python_active_reads_virtualenv
run_test "python activate sources activate"       test_python_activate_sources_activate_script
run_test "python deactivate calls deactivate"     test_python_deactivate_calls_deactivate
run_test "python deactivate safe when unset"      test_python_deactivate_is_safe_when_no_deactivate_defined

test_discovery_finds_python_handler() {
    source "$AUTOENV_SCRIPT"
    [[ " ${_AUTOENV_HANDLERS[*]} " == *" python "* ]] \
        || die "python not in handlers: ${_AUTOENV_HANDLERS[*]}"
}

test_discovery_skips_underscore_prefixed_files() {
    # Copy autoenv.zsh + a custom autoenv.d into tmp so we can stage files.
    local tmp=$(mktemp -d)
    cp "$AUTOENV_SCRIPT" "$tmp/autoenv.zsh"
    mkdir -p "$tmp/autoenv.d"
    echo "_autoenv_live_detect()     { return 1 }" >  "$tmp/autoenv.d/live.zsh"
    echo "_autoenv_live_active()     { }"         >> "$tmp/autoenv.d/live.zsh"
    echo "_autoenv_live_activate()   { }"         >> "$tmp/autoenv.d/live.zsh"
    echo "_autoenv_live_deactivate() { }"         >> "$tmp/autoenv.d/live.zsh"
    echo "LOADED_DISABLED=1" > "$tmp/autoenv.d/_disabled.zsh"
    source "$tmp/autoenv.zsh"
    [[ " ${_AUTOENV_HANDLERS[*]} " == *" live "* ]] \
        || die "live handler not discovered"
    [[ " ${_AUTOENV_HANDLERS[*]} " != *" _disabled "* ]] \
        || die "_disabled should not be registered"
    [[ -z ${LOADED_DISABLED:-} ]] \
        || die "_disabled.zsh was sourced when it shouldn't be"
    rm -rf "$tmp"
}

run_test "discovery finds python"                test_discovery_finds_python_handler
run_test "discovery skips underscore-prefixed"   test_discovery_skips_underscore_prefixed_files

test_dispatch_activates_on_enter() {
    local tmp=$(mktemp -d)
    make_fake_venv "$tmp/.venv"
    source "$AUTOENV_SCRIPT"
    cd "$tmp"
    [[ ${VIRTUAL_ENV:-} == "$tmp/.venv" ]] \
        || die "VIRTUAL_ENV should be $tmp/.venv, got '${VIRTUAL_ENV:-}'"
    [[ ${_AUTOENV_ACTIVE[python]:-} == "$tmp/.venv" ]] \
        || die "_AUTOENV_ACTIVE[python] should be $tmp/.venv, got '${_AUTOENV_ACTIVE[python]:-}'"
    rm -rf "$tmp"
}

test_dispatch_deactivates_on_leave() {
    local tmp=$(mktemp -d)
    local empty=$(mktemp -d)
    make_fake_venv "$tmp/.venv"
    source "$AUTOENV_SCRIPT"
    cd "$tmp"
    cd "$empty"
    [[ -z ${VIRTUAL_ENV:-} ]] \
        || die "VIRTUAL_ENV should be unset after leaving, got '${VIRTUAL_ENV:-}'"
    [[ -z ${_AUTOENV_ACTIVE[python]:-} ]] \
        || die "_AUTOENV_ACTIVE[python] should be unset after leaving"
    rm -rf "$tmp" "$empty"
}

test_dispatch_switches_between_projects() {
    local a=$(mktemp -d) b=$(mktemp -d)
    make_fake_venv "$a/.venv"
    make_fake_venv "$b/.venv"
    source "$AUTOENV_SCRIPT"
    cd "$a"
    [[ ${VIRTUAL_ENV:-} == "$a/.venv" ]] || die "should be in A, got '${VIRTUAL_ENV:-}'"
    cd "$b"
    [[ ${VIRTUAL_ENV:-} == "$b/.venv" ]] || die "should switch to B, got '${VIRTUAL_ENV:-}'"
    [[ ${_AUTOENV_ACTIVE[python]:-} == "$b/.venv" ]] \
        || die "_AUTOENV_ACTIVE[python] should be $b/.venv"
    rm -rf "$a" "$b"
}

test_dispatch_noop_when_state_matches() {
    local tmp=$(mktemp -d)
    make_fake_venv "$tmp/.venv"
    source "$AUTOENV_SCRIPT"
    cd "$tmp"
    local before=$VIRTUAL_ENV
    # Firing chpwd again (cd to same dir) should be a no-op, not a re-source.
    cd "$tmp"
    [[ $VIRTUAL_ENV == $before ]] \
        || die "VIRTUAL_ENV changed on redundant chpwd: '$before' -> '$VIRTUAL_ENV'"
    rm -rf "$tmp"
}

run_test "dispatch: activates on enter"         test_dispatch_activates_on_enter
run_test "dispatch: deactivates on leave"       test_dispatch_deactivates_on_leave
run_test "dispatch: switches between projects"  test_dispatch_switches_between_projects
run_test "dispatch: no-op when state matches"   test_dispatch_noop_when_state_matches

# === summary ===
print
print "Passed: $PASSED"
print "Failed: $FAILED"
(( FAILED == 0 )) || exit 1
