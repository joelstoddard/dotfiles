#!/usr/bin/env zsh
# Tests claude-tmux-state against a fake tmux and fake notifiers that log every call,
# then the hook wiring in .claude/user-settings.json.
# See docs/design/claude-tmux-state.md

REPO="${0:A:h}/../.."
SCRIPT="$REPO/home/files/claude/claude-tmux-state.sh"
FAILS=0

command -v jq >/dev/null || { echo "jq not installed — skipping"; exit 0; }

die() { echo "  FAIL [$1]: $2"; FAILS=1 }

setup() {  # → fakes in $D/bin, every call logged to $D/log
  D=$(mktemp -d); mkdir "$D/bin"; : > "$D/log"
  cat > "$D/bin/tmux" <<'EOF'
#!/usr/bin/env bash
echo "tmux $*" >> "$FAKE_LOG"
case $1 in
  list-clients) printf '%s\n' "${FAKE_CLIENTS:-}" ;;
  display) if [[ $* == *pane_title* ]]; then echo "${FAKE_TITLE-✳ Fix the build}"; else echo "work:3"; fi ;;
esac
exit "${FAKE_TMUX_RC:-0}"
EOF
  for n in osascript notify-send; do
    cat > "$D/bin/$n" <<EOF
#!/usr/bin/env bash
echo "notify $n" >> "\$FAKE_LOG"
for a in "\$@"; do echo "arg:\$a" >> "\$FAKE_LOG"; done
EOF
  done
  chmod +x "$D/bin/"*
}
cleanup() { rm -rf "$D"; unset FAKE_CLIENTS FAKE_TITLE FAKE_TMUX_RC }
# run <state> [stdin] — invoke the script the way a hook does, from pane %7
run() { print -r -- "${2:-}" | FAKE_LOG="$D/log" PATH="$D/bin:$PATH" TMUX_PANE=%7 bash "$SCRIPT" "$1"; RC=$? }
has() { grep -qxF -- "$1" "$D/log" }
notified() { grep -q '^notify' "$D/log" }

echo "--- working and idle set the pane option without notifying"
for s in working idle; do
  setup; run $s
  has "tmux set -p -t %7 @claude $s" || die $s "option not set"
  notified && die $s "notified"
  cleanup
done

echo "--- off unsets the pane option"
setup; run off
has "tmux set -pu -t %7 @claude" || die off "option not unset"
cleanup

echo "--- outside tmux it does nothing"
setup
print -r -- '' | FAKE_LOG="$D/log" PATH="$D/bin:$PATH" TMUX_PANE= bash "$SCRIPT" done; rc=$?
[[ $rc == 0 && ! -s "$D/log" ]] || die no-tmux "rc=$rc log=$(<$D/log)"
cleanup

echo "--- blocked notifies with Claude's message as one unchanged argument"
setup; run blocked "$(jq -nc --arg m "Run \"rm 'x'\"?" '{message:$m}')"
has "tmux set -p -t %7 @claude blocked" || die blocked "option not set"
has "arg:Run \"rm 'x'\"?" || die blocked "message mangled: $(<$D/log)"
has "arg:Claude · work:3" || die blocked "title missing: $(<$D/log)"
cleanup

echo "--- blocked with empty or malformed JSON still notifies"
for input in '' 'not json'; do
  setup; run blocked "$input"
  [[ $RC == 0 ]] || die blocked-bad-json "exited $RC on '$input'"
  has "tmux set -p -t %7 @claude blocked" || die blocked-bad-json "option not set on '$input'"
  has "arg:Claude needs your input" || die blocked-bad-json "no fallback on '$input': $(<$D/log)"
  cleanup
done

echo "--- done notifies with the pane topic, glyph stripped"
setup; run done
has "tmux set -p -t %7 @claude done" || die done "option not set"
has "arg:Done · Fix the build" || die done "topic wrong: $(<$D/log)"
cleanup

echo "--- a title without a glyph is kept whole"
setup; export FAKE_TITLE="Fix the build"; run done
has "arg:Done · Fix the build" || die done-plain "topic wrong: $(<$D/log)"
cleanup

echo "--- done on the pane you are looking at goes idle, silently"
setup; export FAKE_CLIENTS="attached,focused,UTF-8 %7"; run done
has "tmux set -p -t %7 @claude idle" || die watching "not idle"
notified && die watching "notified"
cleanup

echo "--- blocked on the pane you are looking at stays blocked, silently"
setup; export FAKE_CLIENTS="attached,focused,UTF-8 %7"; run blocked '{}'
has "tmux set -p -t %7 @claude blocked" || die watching-blocked "not blocked"
notified && die watching-blocked "notified"
cleanup

echo "--- a focused client on %70, or an unfocused one on %7, is not watching %7"
setup; export FAKE_CLIENTS=$'attached,focused,UTF-8 %70\nattached,UTF-8 %7'; run done
has "tmux set -p -t %7 @claude done" || die other-pane "went idle"
notified || die other-pane "did not notify"
cleanup

echo "--- a failing tmux never fails the hook"
for s in working idle done blocked off; do
  setup; export FAKE_TMUX_RC=1; run $s '{}'
  [[ $RC == 0 ]] || die tmux-down "$s exited $RC"
  cleanup
done

echo "--- an unknown state is ignored"
setup; run bogus
[[ $RC == 0 ]] || die unknown "exited $RC"
grep -q 'set -p' "$D/log" && die unknown "set an option"
cleanup

SETTINGS="$REPO/.claude/user-settings.json"

echo "--- a turn that ends, cleanly or on an API error, marks the pane done"
for ev in Stop StopFailure; do
  jq -e --arg ev $ev '[.hooks[$ev][]?.hooks[].command] | any(endswith("claude-tmux-state done"))' \
    "$SETTINGS" >/dev/null || die turn-end "$ev does not run claude-tmux-state done"
done

echo "--- every hook is silent outside tmux, even where the script is not installed"
for cmd in ${(f)"$(jq -r '.hooks[][].hooks[].command | select(contains("claude-tmux-state"))' "$SETTINGS")"}; do
  print -r -- '{}' | env -u TMUX_PANE PATH=/usr/bin:/bin sh -c "$cmd" >/dev/null 2>&1; rc=$?
  [[ $rc == 0 ]] || die outside-tmux "'$cmd' exited $rc"
done

[[ $FAILS == 0 ]] && echo "OK: claude-tmux-state" || { echo "FAILED: claude-tmux-state"; exit 1 }
