#!/usr/bin/env zsh
# Tests claude-tmux-state against a fake tmux and fake notifiers that log every call,
# then the hook wiring in .claude/user-settings.json.
# See docs/design/claude-tmux-state.md

REPO="${0:A:h}/../.."
SCRIPT="$REPO/home/files/claude/claude-tmux-state.sh"
FAILS=0

command -v jq >/dev/null || { echo "jq not installed — skipping"; exit 0; }

die() { echo "  FAIL [$1]: $2"; FAILS=1 }

setup() {  # → fakes in $D/bin, pane options as files in $D/opt, every call logged to $D/log
  D=$(mktemp -d); mkdir "$D/bin" "$D/opt"; : > "$D/log"; : > "$D/transcript"
  cat > "$D/bin/tmux" <<'EOF'
#!/usr/bin/env bash
echo "tmux $*" >> "$FAKE_LOG"
case $1 in
  set)
    if [[ $2 == -pu ]]; then rm -f "$FAKE_OPT/$5"; else printf '%s' "$6" > "$FAKE_OPT/$5"; fi
    if [[ $5 == @claude && $6 == stopping ]]; then
      # Stand-ins for what happens while the hold waits.
      [[ -n ${FAKE_TRANSCRIPT_TAIL:-} ]] && printf '%s\n' "$FAKE_TRANSCRIPT_TAIL" >> "$FAKE_TRANSCRIPT"
      [[ -n ${FAKE_DURING_HOLD:-} ]] && printf '%s' "$FAKE_DURING_HOLD" > "$FAKE_OPT/@claude"
    fi ;;
  list-clients) printf '%s\n' "${FAKE_CLIENTS:-}" ;;
  display)
    case ${@: -1} in
      *pane_title*) echo "${FAKE_TITLE-✳ Fix the build}" ;;
      *session_name*) echo "work:3" ;;
      '#{@'*'}') f=${@: -1}; f=${f#\#\{}; cat "$FAKE_OPT/${f%\}}" 2>/dev/null; echo ;;
    esac ;;
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
cleanup() { rm -rf "$D"; unset FAKE_CLIENTS FAKE_TITLE FAKE_TMUX_RC FAKE_TRANSCRIPT_TAIL FAKE_DURING_HOLD }
opt() { printf '%s' "$2" > "$D/opt/$1" }  # opt <@name> <value> — preset a pane option
# run <verb> [stdin] — invoke the script the way a hook does, from pane %7
run() {
  print -r -- "${2:-}" | FAKE_LOG="$D/log" FAKE_OPT="$D/opt" FAKE_TRANSCRIPT="$D/transcript" \
    CLAUDE_TMUX_STATE_POLL=0 PATH="$D/bin:$PATH" HOME="$D" TMUX_PANE=%7 bash "$SCRIPT" "$1"; RC=$?
}
on_macos() { printf '#!/bin/sh\necho Darwin\n' > "$D/bin/uname"; chmod +x "$D/bin/uname" }
# notifier_app <exit code> — a fake Claude Notify app in the fake $HOME that logs like the other notifiers
notifier_app() {
  local bin="$D/Applications/Claude Notify.app/Contents/MacOS"
  mkdir -p "$bin"
  printf '#!/bin/sh\necho "notify claude-notify" >> "$FAKE_LOG"\nfor a in "$@"; do echo "arg:$a" >> "$FAKE_LOG"; done\nexit %s\n' "$1" > "$bin/claude-notify"
  chmod +x "$bin/claude-notify"
}
has() { grep -qxF -- "$1" "$D/log" }
notified() { grep -q '^notify' "$D/log" }
now() { cat "$D/opt/@claude" 2>/dev/null }
stop_json() { jq -nc --arg t "$D/transcript" '{hook_event_name:"Stop", transcript_path:$t}' }
SUMMARY='{"type":"system","subtype":"stop_hook_summary","hookErrors":[]}'
BLOCKED_SUMMARY='{"type":"system","subtype":"stop_hook_summary","hookErrors":["File the findings first."]}'
ENDED='{"type":"system","subtype":"turn_duration","durationMs":7148}'
ENDED_WITH_AGENTS='{"type":"system","subtype":"turn_duration","durationMs":6003,"pendingBackgroundAgentCount":1}'

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
setup; run blocked "$(jq -nc --arg m "Run \"rm 'x'\"?" '{notification_type:"permission_prompt",message:$m}')"
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

echo "--- a stop whose turn ends marks the pane done and notifies once"
setup; export FAKE_TRANSCRIPT_TAIL="$SUMMARY"$'\n'"$ENDED"; run stop "$(stop_json)"
has "tmux set -p -t %7 @claude stopping" || die stop-ended "never held"
[[ $(now) == done ]] || die stop-ended "state is '$(now)'"
[[ $(grep -c '^notify' "$D/log") == 1 ]] || die stop-ended "notified $(grep -c '^notify' "$D/log") times"
cleanup

echo "--- a stop that another Stop hook blocks keeps the spinner, silently"
setup; export FAKE_TRANSCRIPT_TAIL="$BLOCKED_SUMMARY"; run stop "$(stop_json)"
[[ $(now) == stopping ]] || die stop-blocked "state is '$(now)'"
notified && die stop-blocked "notified"
cleanup

echo "--- a stop with background agents still running keeps the spinner, silently"
setup; export FAKE_TRANSCRIPT_TAIL="$SUMMARY"$'\n'"$ENDED_WITH_AGENTS"; run stop "$(stop_json)"
[[ $(now) == working ]] || die stop-background "state is '$(now)'"
notified && die stop-background "notified"
cleanup

echo "--- a stop with no recognisable transcript still notifies"
for input in "$(stop_json)" '{}'; do
  setup; run stop "$input"
  [[ $(now) == done ]] || die stop-unknown "state is '$(now)' for $input"
  notified || die stop-unknown "did not notify for $input"
  cleanup
done

echo "--- an event during the hold cancels the stop"
setup; export FAKE_TRANSCRIPT_TAIL="$SUMMARY"$'\n'"$ENDED" FAKE_DURING_HOLD=working; run stop "$(stop_json)"
[[ $(now) == working ]] || die stop-cancelled "state is '$(now)'"
notified && die stop-cancelled "notified"
cleanup

echo "--- a stop while a subagent's prompt is open keeps the pane blocked"
setup; opt @claude blocked; export FAKE_TRANSCRIPT_TAIL="$SUMMARY"$'\n'"$ENDED_WITH_AGENTS"; run stop "$(stop_json)"
[[ $(now) == blocked ]] || die stop-while-blocked "state is '$(now)'"
notified && die stop-while-blocked "notified"
cleanup

echo "--- asking records which agent asks: a subagent's id, or main"
setup; run asking '{"hook_event_name":"PermissionRequest","agent_id":"a1"}'
has "tmux set -p -t %7 @claude-asker a1" || die asking-subagent "$(<$D/log)"
cleanup
setup; run asking '{"hook_event_name":"PermissionRequest"}'
has "tmux set -p -t %7 @claude-asker main" || die asking-main "$(<$D/log)"
cleanup

echo "--- a permission prompt blocks on the asking agent, other dialogs on no one"
setup; opt @claude-asker a1; run blocked '{"notification_type":"permission_prompt"}'
[[ $(cat "$D/opt/@claude-blocker") == a1 ]] || die blocker-permission "blocker is '$(cat "$D/opt/@claude-blocker")'"
cleanup
setup; opt @claude-asker a1; run blocked '{"notification_type":"elicitation_dialog"}'
[[ -z $(cat "$D/opt/@claude-blocker" 2>/dev/null) ]] || die blocker-dialog "blocker is '$(cat "$D/opt/@claude-blocker")'"
cleanup

echo "--- while blocked, another agent's tool call keeps the red"
for input in '{"hook_event_name":"PostToolUse","agent_id":"a2"}' '{"hook_event_name":"PostToolUse"}'; do
  setup; opt @claude blocked; opt @claude-blocker a1; run working "$input"
  [[ $(now) == blocked ]] || die other-agent "state is '$(now)' after $input"
  cleanup
done

echo "--- the blocked agent's own tool call clears the red"
setup; opt @claude blocked; opt @claude-blocker a1; run working '{"hook_event_name":"PostToolUse","agent_id":"a1"}'
[[ $(now) == working ]] || die blocker-agent "state is '$(now)'"
cleanup

echo "--- a new prompt from you clears any block"
setup; opt @claude blocked; opt @claude-blocker a1; run working '{"hook_event_name":"UserPromptSubmit"}'
[[ $(now) == working ]] || die prompt-clears "state is '$(now)'"
cleanup

echo "--- a block with no recorded blocker clears on any tool call"
setup; opt @claude blocked; opt @claude-blocker ""; run working '{"hook_event_name":"PostToolUse","agent_id":"a2"}'
[[ $(now) == working ]] || die no-blocker "state is '$(now)'"
cleanup

echo "--- the session's custom title (/rename) names the notification"
setup; run idle '{"hook_event_name":"SessionStart","session_title":"Fix CI"}'; run done
has "arg:Claude · Fix CI" || die title-start "title wrong: $(<$D/log)"
cleanup
setup; opt @claude-title "Fix CI"; run working '{"hook_event_name":"UserPromptSubmit","session_title":"Renamed"}'; run blocked '{}'
has "arg:Claude · Renamed" || die title-rename "title wrong: $(<$D/log)"
cleanup

echo "--- a tool call, which carries no title, keeps it"
setup; opt @claude-title "Fix CI"; run working '{"hook_event_name":"PostToolUse"}'; run done
has "arg:Claude · Fix CI" || die title-kept "title wrong: $(<$D/log)"
cleanup

echo "--- a session without a custom title falls back to tmux session:window, even after a named one"
setup; opt @claude-title "Old"; run idle '{"hook_event_name":"SessionStart","source":"resume"}'; run done
has "arg:Claude · work:3" || die title-fallback "title wrong: $(<$D/log)"
cleanup

echo "--- on macOS the Claude Notify app gets the title and body, so the banner has Claude's icon"
setup; on_macos; notifier_app 0; run done
has "notify claude-notify" || die app "app not used: $(<$D/log)"
[[ $(grep -A2 '^notify claude-notify' "$D/log") == $'notify claude-notify\narg:work:3\narg:Done · Fix the build' ]] \
  || die app "args wrong: $(<$D/log)"
has "notify osascript" && die app "osascript also notified"
cleanup

echo "--- on macOS a missing or refusing app falls back to osascript"
setup; on_macos; run done
has "notify osascript" || die app-missing "no fallback: $(<$D/log)"
cleanup
setup; on_macos; notifier_app 1; run done
has "notify osascript" || die app-refused "no fallback: $(<$D/log)"
has "arg:Claude · work:3" || die app-refused "fallback title lacks the Claude prefix: $(<$D/log)"
cleanup

echo "--- a failing tmux never fails the hook"
for s in working idle done blocked asking stop off; do
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
hook() { jq -c --arg ev $1 '[.hooks[$ev][]?.hooks[] | select(.command | contains("claude-tmux-state"))]' "$SETTINGS" }

echo "--- Stop holds in the background; an API error ends the turn at once"
[[ $(hook Stop | jq -r '.[0] | "\(.command | split(" ") | last) \(.async)"') == "stop true" ]] \
  || die stop-hook "Stop runs $(hook Stop)"
[[ $(hook StopFailure | jq -r '.[0].command | split(" ") | last') == done ]] \
  || die stopfailure-hook "StopFailure runs $(hook StopFailure)"

echo "--- a permission request records the asking agent"
[[ $(hook PermissionRequest | jq -r '.[0].command | split(" ") | last') == asking ]] \
  || die asking-hook "PermissionRequest runs $(hook PermissionRequest)"

echo "--- every hook is silent outside tmux, even where the script is not installed"
for cmd in ${(f)"$(jq -r '.hooks[][].hooks[].command | select(contains("claude-tmux-state"))' "$SETTINGS")"}; do
  print -r -- '{}' | env -u TMUX_PANE PATH=/usr/bin:/bin sh -c "$cmd" >/dev/null 2>&1; rc=$?
  [[ $rc == 0 ]] || die outside-tmux "'$cmd' exited $rc"
done

[[ $FAILS == 0 ]] && echo "OK: claude-tmux-state" || { echo "FAILED: claude-tmux-state"; exit 1 }
