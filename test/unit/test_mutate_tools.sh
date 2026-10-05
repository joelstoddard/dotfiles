#!/usr/bin/env zsh
# Tests test/mutate.sh against small fixture repos. See docs/design/coverage-and-mutation.md

REPO="${0:A:h}/../.."
TOOL="${MUTATE_TOOL:-$REPO/test/mutate.sh}"
FAILS=0

die() { echo "  FAIL [$1]: $2"; FAILS=1 }

setup() {  # → a fixture repo in $D: m.sh has a caught mutant, a missed one and an uncovered branch
  D=$(mktemp -d); mkdir -p "$D/home/files" "$D/test/unit"
  cat > "$D/home/files/m.sh" <<'EOF'
# fixture
if [[ ${1:-} == yes ]]; then
  echo "took yes"
else
  echo "took no"
fi
echo "side note" >/dev/null
EOF
  cat > "$D/test/unit/test_m.sh" <<'EOF'
[[ $(bash "${0:A:h}/../../home/files/m.sh" yes) == "took yes" ]]
EOF
}
cleanup() { rm -rf "$D" }
mut() { OUTPUT=$(COV_LOG= COVERAGE_ROOT="$D" bash "$TOOL" "$@" 2>&1); RC=$? }
row() { print -r -- "$OUTPUT" | awk -v f="$1" '$NF == f { print $1, $2 }' }  # → "killed/scored score"
hang_fixture() {  # → $H: a file whose `false` mutant hangs its test; the clean test takes 0.5s, so the hang limit is about 5s
  H=hang_$RANDOM$RANDOM
  print -r -- $'while false; do :; done\necho looped' > "$D/home/files/$H.sh"
  print -r -- "sleep 0.5; [[ \$(bash \"\${0:A:h}/../../home/files/$H.sh\") == looped ]]" > "$D/test/unit/test_n.sh"
}
status_of() { awk -F'\t' -v l="$1" -v o="$2" '$3 == l && $4 == o { print $1 }' "$D/.coverage/mutants.tsv" }

echo "--- a mutant a test catches is killed, and one it misses survives"
setup; mut
[[ $RC == 0 && $(row home/files/m.sh) == "2/3 66.6" ]] || die score "rc=$RC: $OUTPUT"
[[ $(status_of 2 '==') == killed && $(status_of 3 delete) == killed ]] || die killed "$(<"$D/.coverage/mutants.tsv")"
[[ $OUTPUT == *'survived  home/files/m.sh:7  delete  echo "side note" >/dev/null  ->  :'* ]] || die survivor "$OUTPUT"
cleanup

echo "--- a mutant keeps the backslashes of its line exactly"
setup
print -r -- $'v=\'a\\nb\'; [[ ${#v} == 4 ]] && echo four' > "$D/home/files/e.sh"
print -r -- '[[ $(bash "${0:A:h}/../../home/files/e.sh") == four ]]' > "$D/test/unit/test_e.sh"
mut home/files/e.sh
[[ $(status_of 1 '==') == killed && $(status_of 1 '&&') == killed ]] || die backslash "$(<"$D/.coverage/mutants.tsv")"
cleanup

echo "--- an uncovered line gets no mutants"
setup; mut
[[ -z $(awk -F'\t' '$3 == 5' "$D/.coverage/mutants.tsv") ]] || die uncovered "$(<"$D/.coverage/mutants.tsv")"
cleanup

echo "--- an ignore entry with a reason takes its mutant out of the score"
setup
print -r -- $'home/files/m.sh\tdelete\techo "side note" >/dev/null\toutput goes to /dev/null' > "$D/test/mutants-ignore.tsv"
mut
[[ $RC == 0 && $(row home/files/m.sh) == "2/2 100.0" && $OUTPUT != *survived* ]] || die ignored "rc=$RC: $OUTPUT"
[[ $(status_of 7 delete) == ignored ]] || die ignored-status "$(<"$D/.coverage/mutants.tsv")"
cleanup

echo "--- an ignore entry without a reason is refused"
setup; print -r -- $'home/files/m.sh\tdelete\techo "side note" >/dev/null\t' > "$D/test/mutants-ignore.tsv"; mut
[[ $RC == 2 && $OUTPUT == *"has no reason"* ]] || die no-reason "rc=$RC: $OUTPUT"
cleanup

echo "--- a mutant that makes a test hang counts as killed, and leaves no process behind"
setup; hang_fixture
mut home/files/$H.sh
[[ $(status_of 1 false) == killed && $(row home/files/$H.sh) == "2/2 100.0" ]] || die hang "rc=$RC: $OUTPUT"
[[ -z $(pgrep -f "$H.sh") ]] || { die orphan "still running: $(pgrep -fl "$H.sh")"; pkill -9 -f "$H.sh" }
[[ $OUTPUT != *"Alarm clock"* ]] || die alarm-noise "$OUTPUT"
cleanup

echo "--- killing the run takes a hung test with it"
setup; hang_fixture
COV_LOG= COVERAGE_ROOT="$D" perl -e 'setpgrp(0, 0); exec @ARGV' bash "$TOOL" "home/files/$H.sh" >/dev/null 2>&1 &
RUN=$!
IN_TEST="\.\./home/files/$H.sh"  # the test's own process, not the run's command line
for _ in {1..100}; do  # in flight = still there after 0.3s; the unmutated runs exit in milliseconds
  [[ -n $(pgrep -f "$IN_TEST") ]] && { sleep 0.3; [[ -n $(pgrep -f "$IN_TEST") ]] && break }
  sleep 0.1
done
[[ -n $(pgrep -f "$IN_TEST") ]] || die term-start "the hung test never started"
kill -TERM -- -$RUN; wait $RUN 2>/dev/null
for _ in {1..20}; do [[ -z $(pgrep -f "$H.sh") ]] && break; sleep 0.1; done  # the wrapper can kill the group after the run has exited
[[ -z $(pgrep -f "$H.sh") ]] || { die term-orphan "still running: $(pgrep -fl "$H.sh")"; pkill -9 -f "$H.sh" }
cleanup

echo "--- a test that exits leaving a background process behind leaves nothing running"
setup; B=bg_$RANDOM$RANDOM; N=$((100000 + RANDOM))
print -r -- "if [[ \${1:-} == go ]]; then echo done; else sleep $N >/dev/null 2>&1 & echo done; fi" > "$D/home/files/$B.sh"
print -r -- "[[ \$(bash \"\${0:A:h}/../../home/files/$B.sh\" go) == done ]]" > "$D/test/unit/test_b.sh"
mut home/files/$B.sh
[[ $(status_of 1 '==') == survived ]] || die bg-start "rc=$RC: $OUTPUT"
[[ -z $(pgrep -f "sleep $N") ]] || { die bg-orphan "still running: $(pgrep -fl "sleep $N")"; pkill -9 -f "sleep $N" }
cleanup

echo "--- a mutant that does not parse is invalid and out of the score"
setup
print -r -- $'echo one; echo "a\nb"' > "$D/home/files/i.sh"
print -r -- '[[ $(bash "${0:A:h}/../../home/files/i.sh") == $'"'"'one\na\nb'"'"' ]]' > "$D/test/unit/test_i.sh"
mut home/files/i.sh
[[ $(status_of 1 delete) == invalid && $(row home/files/i.sh) == "0/0 100.0" ]] || die invalid-bash "rc=$RC: $OUTPUT"
cleanup

echo "--- a .zsh file is parsed by zsh, not bash"
setup
print -r -- $'for i (1 2) print -r -- $i\necho "a\nb"\n[[ -n $i ]] && print -r -- ok' > "$D/home/files/z.zsh"
print -r -- '[[ $(zsh "${0:A:h}/../../home/files/z.zsh") == $'"'"'1\n2\na\nb\nok'"'"' ]]' > "$D/test/unit/test_z.sh"
mut home/files/z.zsh
[[ $(status_of 2 delete) == invalid && $(status_of 4 '&&') == killed && $(row home/files/z.zsh) == "2/2 100.0" ]] || die invalid-zsh "rc=$RC: $OUTPUT"
cleanup

echo "--- a measured file that does not parse stops the run"
setup; print -r -- 'echo "unterminated' > "$D/home/files/bad.sh"; mut
[[ $RC == 1 && $OUTPUT == *"home/files/bad.sh does not parse"* ]] || die unparsable "rc=$RC: $OUTPUT"
cleanup

echo "--- a measured file whose tests did not run stops the run"
setup
print 'echo s' > "$D/home/files/s.sh"
print 'exit 0' > "$D/test/unit/test_s.sh"
mut home/files/s.sh
[[ $RC == 1 && $OUTPUT == *"home/files/s.sh has no covered line"* ]] || die uncovered-file "rc=$RC: $OUTPUT"
cleanup

echo "--- a failing suite stops the run before any mutant"
setup; print 'exit 1' > "$D/test/unit/test_broken.sh"; mut
[[ $RC == 1 && $OUTPUT == *"suites fail"* ]] || die red "rc=$RC: $OUTPUT"
cleanup

echo "--- a file outside the measured set is refused"
setup; mut home/nope.sh
[[ $RC == 2 && $OUTPUT == *"not a measured file"* ]] || die unmeasured "rc=$RC: $OUTPUT"
cleanup

echo "--- a test wrapper that fails by itself (exit 127 or 255) fails the run, and no mutant counts as killed"
for code in 127 255; do
  setup; mkdir "$D/bin"
  cat > "$D/bin/perl" <<EOF
#!/usr/bin/env bash
n=\$(( \$(cat "$D/calls" 2>/dev/null || echo 0) + 1 )); echo \$n > "$D/calls"
((n <= 1)) && exec $(command -v perl) "\$@"
exit $code
EOF
  chmod +x "$D/bin/perl"
  OUTPUT=$(PATH="$D/bin:$PATH" COV_LOG= COVERAGE_ROOT="$D" bash "$TOOL" -j 1 2>&1); RC=$?
  [[ $RC == 1 && $OUTPUT == *"a mutation worker failed"* ]] || die "wrapper-$code" "rc=$RC: $OUTPUT"
  [[ $(<"$D/calls") -ge 2 && ! -e $D/.coverage/mutants.tsv ]] || die "wrapper-$code-scored" "calls=$(<"$D/calls"): $OUTPUT"
  cleanup
done

echo "--- a file named twice is mutated once"
setup; mut home/files/m.sh home/files/m.sh
[[ $RC == 0 && $(row home/files/m.sh) == "2/3 66.6" && $(print -r -- "$OUTPUT" | grep -c 'm\.sh$') == 1 && \
  $(print -r -- "$OUTPUT" | awk '$NF == "TOTAL" { print $1 }') == 2/3 ]] || die twice "rc=$RC: $OUTPUT"
cleanup

echo "--- --changed mutates only the measured files changed since main"
setup
print 'echo g' > "$D/home/files/g.sh"
print -r -- '[[ $(bash "${0:A:h}/../../home/files/g.sh") == g ]]' > "$D/test/unit/test_g.sh"
git -C "$D" init -q && git -C "$D" add -A &&
  git -C "$D" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -qm seed &&
  git -C "$D" update-ref refs/remotes/origin/main HEAD
print '# changed' >> "$D/home/files/g.sh"
mut --changed
[[ $RC == 0 && -n $(row home/files/g.sh) && -z $(row home/files/m.sh) ]] || die changed "rc=$RC: $OUTPUT"
cleanup

echo "--- one worker and many workers give the same results"
setup; mut -j 1; one=$(<"$D/.coverage/mutants.tsv"); mut -j 3
[[ $RC == 0 && $(<"$D/.coverage/mutants.tsv") == "$one" ]] || die workers "differs: $(<"$D/.coverage/mutants.tsv")"
cleanup

[[ $FAILS == 0 ]] && echo "OK: mutate-tools" || { echo "FAILED: mutate-tools"; exit 1 }
