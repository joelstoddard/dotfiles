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

# === summary ===
print
print "Passed: $PASSED"
print "Failed: $FAILED"
(( FAILED == 0 )) || exit 1
