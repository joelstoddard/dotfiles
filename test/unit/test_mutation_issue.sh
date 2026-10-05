#!/usr/bin/env zsh
# Tests test/mutation-issue.sh against a fake gh that logs its calls and keeps the issue body.
# See docs/design/coverage-and-mutation.md

REPO="${0:A:h}/../.."
SCRIPT="$REPO/test/mutation-issue.sh"
FAILS=0
URL=https://example.invalid/run/1

die() { echo "  FAIL [$1]: $2"; FAILS=1 }

setup() {  # → a fake gh in $D/bin; $1 is the number of the open mutation issue, or empty
  D=$(mktemp -d); mkdir "$D/bin"; : > "$D/log"
  cat > "$D/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "gh $*" >> "$FAKE_DIR/log"
[[ "$1 $2" == "issue list" ]] && echo "${FAKE_OPEN:-}"
[[ -n ${FAKE_FAIL:-} && "$1 $2" == "$FAKE_FAIL" ]] && exit 1
for ((i = 1; i <= $#; i++)); do [[ ${!i} == --body-file ]] && { j=$((i + 1)); cp "${!j}" "$FAKE_DIR/body"; }; done
exit 0
EOF
  chmod +x "$D/bin/gh"
  export FAKE_OPEN=$1
}
cleanup() { rm -rf "$D"; unset FAKE_OPEN FAKE_FAIL }
report() {  # <with survivors: 0|1> → $D/report, shaped like test/mutate.sh prints
  print -r -- $'   killed  score  file\n     2/3   66.6  home/files/m.sh\n     2/3   66.6  TOTAL' > "$D/report"
  (( $1 )) && print -r -- $'\nsurvived  home/files/m.sh:7  delete  echo x  ->  :' >> "$D/report"
}
run() { FAKE_DIR="$D" PATH="$D/bin:$PATH" bash "$SCRIPT" "$@" >/dev/null 2>&1; RC=$? }
called() { grep -q -- "$1" "$D/log" }

echo "--- survivors and no open issue: create one, with the report and the run link"
setup ""; report 1; run "$D/report" "$URL"
called 'gh issue create --title Mutation testing: surviving mutants --label mutation --body-file' || die create "$(<$D/log)"
called 'gh label create mutation' || die label "$(<$D/log)"
[[ $(<$D/body) == *'home/files/m.sh:7  delete'* && $(<$D/body) == *"Run: $URL"* ]] || die body "$(<$D/body)"
cleanup

echo "--- survivors and an open issue: edit it, never open a second"
setup 7; report 1; run "$D/report" "$URL"
called 'gh issue edit 7 --body-file' || die edit "$(<$D/log)"
called 'gh issue create' && die duplicate "$(<$D/log)"
cleanup

echo "--- no survivors and an open issue: close it"
setup 7; report 0; run "$D/report" "$URL"
called "gh issue close 7 --comment No surviving mutants in $URL" || die close "$(<$D/log)"
cleanup

echo "--- no survivors and no open issue: change nothing"
setup ""; report 0; run "$D/report" "$URL"
[[ $(grep -vc '^gh issue list' "$D/log") == 0 ]] || die nothing "$(<$D/log)"
cleanup

echo "--- an unreadable report fails the step"
setup ""; run "$D/missing" "$URL"
[[ $RC == 1 ]] || die unreadable "rc=$RC"
cleanup

echo "--- a report that scored nothing never touches the issue"
setup 7; print -r -- $'   killed  score  file\n     0/0   100.0  home/files/m.sh\n     0/0   100.0  TOTAL' > "$D/report"; run "$D/report" "$URL"
[[ $RC == 1 ]] || die zero-rc "rc=$RC"
[[ ! -s $D/log ]] || die zero-gh "$(<$D/log)"
cleanup

echo "--- a report with no table never touches the issue"
setup 7; print -r -- 'mutate: no measured files to mutate' > "$D/report"; run "$D/report" "$URL"
[[ $RC == 1 ]] || die notable-rc "rc=$RC"
[[ ! -s $D/log ]] || die notable-gh "$(<$D/log)"
cleanup

echo "--- an empty report never touches the issue"
setup 7; : > "$D/report"; run "$D/report" "$URL"
[[ $RC == 1 ]] || die empty-rc "rc=$RC"
[[ ! -s $D/log ]] || die empty-gh "$(<$D/log)"
cleanup

echo "--- a failing gh call fails the step"
setup 7; FAKE_FAIL='issue edit'; export FAKE_FAIL; report 1; run "$D/report" "$URL"
[[ $RC != 0 ]] || die ghfail "rc=$RC"
cleanup

[[ $FAILS == 0 ]] && echo "OK: mutation-issue" || { echo "FAILED: mutation-issue"; exit 1 }
