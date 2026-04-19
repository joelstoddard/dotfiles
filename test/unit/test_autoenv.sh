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

# === summary ===
print
print "Passed: $PASSED"
print "Failed: $FAILED"
(( FAILED == 0 )) || exit 1
