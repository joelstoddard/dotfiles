#!/usr/bin/env zsh
# Tests test/coverage.sh against small fixture repos: tracing, the executable-line
# heuristic, floors and the ratchet. See docs/design/coverage-and-mutation.md

REPO="${0:A:h}/../.."
TOOL="${COVERAGE_TOOL:-$REPO/test/coverage.sh}"
FAILS=0

die() { echo "  FAIL [$1]: $2"; FAILS=1 }

setup() {  # → a fixture repo in $D with one measured bash file and its test
  D=$(mktemp -d); mkdir -p "$D/home/files" "$D/test/unit"
  cat > "$D/home/files/f.sh" <<'EOF'
# fixture
if [[ ${1:-} == yes ]]; then
  echo "took yes"
else
  echo "took no"
fi
EOF
  cat > "$D/test/unit/test_f.sh" <<'EOF'
[[ $(bash "${0:A:h}/../../home/files/f.sh" yes) == "took yes" ]]
EOF
}
cleanup() { rm -rf "$D" }
cov() { OUTPUT=$(COVERAGE_ROOT="$D" bash "$TOOL" "$@" 2>&1); RC=$? }
row() { print -r -- "$OUTPUT" | awk -v f="$1" '$NF == f { print $(NF-3), $(NF-2), $1 }' }  # → "hit/exec pct status"

echo "--- a branch the test never takes counts against coverage"
setup; cov --update
[[ $(row home/files/f.sh) == "2/3 66.6 NO" ]] || die branch "row is '$(row home/files/f.sh)'"
cleanup

echo "--- zsh files sourced by a test are traced, functions included"
setup
cat > "$D/home/files/g.zsh" <<'EOF'
pick() {
  if [[ $1 == yes ]]; then
    print "took yes"
  else
    print "took no"
  fi
}
EOF
cat > "$D/test/unit/test_g.sh" <<'EOF'
source "${0:A:h}/../../home/files/g.zsh"
[[ $(pick yes) == "took yes" ]]
EOF
cov --update
[[ $(row home/files/g.zsh) == "2/3 66.6 NO" ]] || die zsh "row is '$(row home/files/g.zsh)'"
cleanup

echo "--- comments, keywords, heredoc bodies, string continuations and ignored lines are not executable"
D=$(mktemp -d)
cat > "$D/h.sh" <<'EOF'
# a comment
for x in a b; do
  echo "$x"
done
cat <<'BODY'
if this were code
BODY
jq -n '
  1 + 1'
case $1 in
  a | b)
    echo ab
    ;;
  c) ;;
esac
exit 3 # coverage: ignore unreachable after the case above
f() {
  echo in-f
}
EOF
lines=$(bash "$TOOL" --lines "$D/h.sh" | tr '\n' ' ')
[[ $lines == "2 3 5 8 10 12 18 " ]] || die heuristic "executable lines are '$lines'"
cleanup

echo "--- a hit on a later line of a multi-line command is credited to the command's counted line"
setup
cat > "$D/home/files/m.sh" <<'EOF'
x=$(printf '%s' "a
b")
echo one \
  two
echo done
EOF
print 'bash "${0:A:h}/../../home/files/m.sh" >/dev/null' > "$D/test/unit/test_m.sh"
cov --update
[[ $(row home/files/m.sh) == "3/3 100.0 NO" ]] || die span-credit "row is '$(row home/files/m.sh)'"
[[ $(awk -F'\t' '$2 == "home/files/m.sh" { print $3 }' "$D/.coverage/hits.tsv" | tr '\n' ' ') == "1 3 5 " ]] || die span-hits "hits are '$(<"$D/.coverage/hits.tsv")'"
cleanup

echo "--- a multi-line command the test never reaches stays uncovered"
setup
cat > "$D/home/files/m.sh" <<'EOF'
if [[ ${1:-} == yes ]]; then
  echo "took yes"
else
  echo "took no \
  twice"
fi
EOF
print 'bash "${0:A:h}/../../home/files/m.sh" yes >/dev/null' > "$D/test/unit/test_m.sh"
cov --update
[[ $(row home/files/m.sh) == "2/3 66.6 NO" ]] || die span-uncovered "row is '$(row home/files/m.sh)'"
cleanup

echo "--- a measured file with no executable lines counts as fully covered"
setup; print '# only a comment' > "$D/home/files/empty.sh"; cov --update
[[ $(row home/files/empty.sh) == "0/0 100.0 NO" ]] || die empty "row is '$(row home/files/empty.sh)'"
cleanup

echo "--- a failing test stops the run"
setup; print 'exit 1' > "$D/test/unit/test_broken.sh"; cov
[[ $RC == 1 && $OUTPUT == *"test_broken.sh failed"* ]] || die red-suite "rc=$RC: $OUTPUT"
cleanup

echo "--- a measured file without a floor fails"
setup; cov
[[ $RC == 1 && $(row home/files/f.sh) == *"NO" ]] || die no-floor "rc=$RC: $OUTPUT"
cleanup

echo "--- --update records floors, after which the check passes"
setup; cov --update; cov
[[ $RC == 0 ]] || die update "rc=$RC: $OUTPUT"
[[ $(<"$D/test/coverage-floor.tsv") == $'home/files/f.sh\t66.6\nTOTAL\t66.6' ]] || die update "floors are '$(<"$D/test/coverage-floor.tsv")'"
cleanup

echo "--- coverage below its floor fails, and --update never lowers the floor"
setup; print -r -- $'home/files/f.sh\t90.0\nTOTAL\t66.6' > "$D/test/coverage-floor.tsv"; cov
[[ $RC == 1 && $(row home/files/f.sh) == *"LOW" ]] || die low "rc=$RC: $OUTPUT"
cov --update
[[ $RC == 1 && $(<"$D/test/coverage-floor.tsv") == *$'f.sh\t90.0'* ]] || die no-lowering "rc=$RC, floors '$(<"$D/test/coverage-floor.tsv")'"
cleanup

echo "--- the ratchet fails on a lowered or vanished floor, and passes otherwise"
setup
print -r -- $'home/files/f.sh\t66.6\nTOTAL\t66.6' > "$D/test/coverage-floor.tsv"
print -r -- $'home/files/f.sh\t70.0\nTOTAL\t66.6' > "$D/base.tsv"; cov --ratchet "$D/base.tsv"
[[ $RC == 1 && $OUTPUT == *"floor lowered: home/files/f.sh"* ]] || die ratchet-lowered "rc=$RC: $OUTPUT"
print -r -- $'home/files/f.sh\t66.6\nhome/files/gone.sh\t50.0\nTOTAL\t66.6' > "$D/base.tsv"; cov --ratchet "$D/base.tsv"
[[ $RC == 0 ]] || die ratchet-deleted-file "rc=$RC: $OUTPUT"
print -r -- 'kept' > "$D/home/files/gone.sh"; cov --ratchet "$D/base.tsv"
[[ $RC == 1 && $OUTPUT == *"floor removed: home/files/gone.sh"* ]] || die ratchet-removed "rc=$RC: $OUTPUT"
print -r -- $'home/files/f.sh\t60.0\nTOTAL\t60.0' > "$D/base.tsv"; cov --ratchet "$D/base.tsv"
[[ $RC == 0 ]] || die ratchet-raised "rc=$RC: $OUTPUT"
print -r -- $'home/files/f.sh\t66.6' > "$D/test/coverage-floor.tsv"
print -r -- $'home/files/f.sh\t66.6\nTOTAL\t66.6' > "$D/base.tsv"; cov --ratchet "$D/base.tsv"
[[ $RC == 1 && $OUTPUT == *"floor removed: TOTAL"* ]] || die ratchet-total "rc=$RC: $OUTPUT"
cleanup

echo "--- the ratchet compares a second floor file when one is named, and ignores the coverage floors"
setup
print -r -- $'home/files/f.sh\t10.0\nTOTAL\t10.0' > "$D/test/coverage-floor.tsv"
print -r -- $'home/files/f.sh\t70.0\nTOTAL\t70.0' > "$D/base.tsv"
print -r -- $'home/files/f.sh\t60.0\nTOTAL\t70.0' > "$D/other.tsv"; cov --ratchet "$D/base.tsv" "$D/other.tsv"
[[ $RC == 1 && $OUTPUT == *"floor lowered: home/files/f.sh 70.0 -> 60.0"* ]] || die ratchet-other-lowered "rc=$RC: $OUTPUT"
print -r -- $'home/files/f.sh\t80.0\nTOTAL\t70.0' > "$D/other.tsv"; cov --ratchet "$D/base.tsv" "$D/other.tsv"
[[ $RC == 0 ]] || die ratchet-other-raised "rc=$RC: $OUTPUT"
cleanup

echo "--- a file run through a symlinked path is credited to its real path"
setup; ln -s "$D/home/files" "$D/alias"
cat > "$D/test/unit/test_f.sh" <<'EOF'
[[ $(bash "${0:A:h}/../../alias/f.sh" yes) == "took yes" ]]
EOF
cov --update
[[ $(row home/files/f.sh) == "2/3 66.6 NO" ]] || die symlink "row is '$(row home/files/f.sh)'"
cleanup

echo "--- the tracer records exactly the lines the test ran, under the unit__ log prefix"
setup; cov --update
[[ $(grep home/files/f.sh "$D/.coverage/hits.tsv") == $'unit__test_f.sh\thome/files/f.sh\t2\nunit__test_f.sh\thome/files/f.sh\t3' ]] || die hits-rows "rows are '$(<"$D/.coverage/hits.tsv")'"
cleanup

echo "--- a path with two floors fails the check and the ratchet"
setup
print -r -- $'home/files/f.sh\t99.9\nhome/files/f.sh\t10.0\nTOTAL\t66.6' > "$D/test/coverage-floor.tsv"; cov
[[ $RC == 1 ]] || die duplicate-floor "check rc=$RC: $OUTPUT"
print -r -- $'home/files/f.sh\t99.9\nTOTAL\t66.6' > "$D/base.tsv"; cov --ratchet "$D/base.tsv"
[[ $RC == 1 && $OUTPUT == *"floor invalid: home/files/f.sh"* ]] || die duplicate-floor-ratchet "rc=$RC: $OUTPUT"
cleanup

echo "--- a floor that is not a number fails the check and the ratchet"
setup
print -r -- $'home/files/f.sh\t66.6\nTOTAL\tn/a' > "$D/test/coverage-floor.tsv"; cov
[[ $RC == 1 ]] || die malformed-floor "check rc=$RC: $OUTPUT"
print -r -- $'home/files/f.sh\t66.6\nTOTAL\t99.9' > "$D/base.tsv"; cov --ratchet "$D/base.tsv"
[[ $RC == 1 && $OUTPUT == *"floor invalid: TOTAL"* ]] || die malformed-floor-ratchet "rc=$RC: $OUTPUT"
cleanup

echo "--- --update leaves a floor file with a malformed value untouched"
setup; print -r -- $'home/files/f.sh\t66.6\nTOTAL\tn/a' > "$D/test/coverage-floor.tsv"; cov --update
[[ $RC == 1 && $(<"$D/test/coverage-floor.tsv") == $'home/files/f.sh\t66.6\nTOTAL\tn/a' ]] || die update-malformed "rc=$RC, floors '$(<"$D/test/coverage-floor.tsv")'"
cleanup

echo "--- a traced file outside the repo, sorted last, does not abort the run"
setup; O="${D}0"; mkdir "$O"; print true > "$O/s.sh"
print -r -- "bash $O/s.sh" > "$D/test/unit/test_z.sh"
cov --update
[[ $RC == 0 && $(row home/files/f.sh) == "2/3 66.6 NO" ]] || die outside-last "rc=$RC: $OUTPUT"
rm -rf "$O"; cleanup

echo "--- --update raises an existing floor to the current value"
setup; print -r -- $'home/files/f.sh\t50.0\nTOTAL\t50.0' > "$D/test/coverage-floor.tsv"; cov --update
[[ $(<"$D/test/coverage-floor.tsv") == $'home/files/f.sh\t66.6\nTOTAL\t66.6' ]] || die raise "floors are '$(<"$D/test/coverage-floor.tsv")'"
cleanup

echo "--- the ratchet fails on a last base row with no trailing newline"
setup
print -r -- $'home/files/f.sh\t66.6\nTOTAL\t66.6' > "$D/test/coverage-floor.tsv"
print -rn -- $'home/files/f.sh\t66.6\nTOTAL\t99.9' > "$D/base.tsv"; cov --ratchet "$D/base.tsv"
[[ $RC == 1 && $OUTPUT == *"floor lowered: TOTAL"* ]] || die ratchet-no-newline "rc=$RC: $OUTPUT"
cleanup

echo "--- --files lists exactly the measured files"
setup; print 'not shell' > "$D/home/files/notes.txt"; cov --files
[[ $RC == 0 && $OUTPUT == "home/files/f.sh" ]] || die files "rc=$RC: '$OUTPUT'"
cleanup

echo "--- --trace records hits without checking floors, and stops on a failing test"
setup; cov --trace
[[ $RC == 0 && -z $OUTPUT ]] || die trace "rc=$RC: '$OUTPUT'"
[[ $(awk -F'\t' '$2 == "home/files/f.sh" { print $3 }' "$D/.coverage/hits.tsv" | tr '\n' ' ') == "2 3 " ]] || die trace-hits "$(<"$D/.coverage/hits.tsv")"
print 'exit 1' > "$D/test/unit/test_broken.sh"; cov --trace
[[ $RC == 1 && $OUTPUT == *"test_broken.sh failed"* ]] || die trace-red "rc=$RC: $OUTPUT"
[[ ! -e $D/.coverage/hits.tsv ]] || die trace-red-hits "stale hits left behind"
cleanup

[[ $FAILS == 0 ]] && echo "OK: coverage-tools" || { echo "FAILED: coverage-tools"; exit 1 }
