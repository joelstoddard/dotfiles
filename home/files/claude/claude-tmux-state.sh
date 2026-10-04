# shellcheck shell=bash
# Claude Code hook: records this pane's Claude state in tmux, and notifies when it needs you.
# Usage: claude-tmux-state idle|working|asking|blocked|stop|done|off  (hook JSON on stdin)
# See docs/design/claude-tmux-state.md
set -euo pipefail
trap 'exit 0' EXIT # never fail the hook: exit 2 from Stop keeps Claude running

verb=${1:-}
pane=${TMUX_PANE:-}
[[ -n $pane ]] || exit 0

get() { tmux display -p -t "$pane" "#{$1}"; }
put() { tmux set -p -t "$pane" "$@"; }
field() { jq -r "$1 // empty" <<<"$json" 2>/dev/null || true; }

watching() { # a focused client is showing this pane
  grep -q "focused.* $pane\$" <<<"$(tmux list-clients -F '#{client_flags} #{pane_id}')"
}

notify() { # notify <body>
  local title
  title="Claude · $(tmux display -p -t "$pane" '#{session_name}:#{window_index}')"
  # Arguments only: the text can hold commands Claude wrote.
  if [[ $(uname) == Darwin ]]; then
    # The app shows Claude's icon; osascript shows Script Editor's. Built by home/claude.nix.
    "$HOME/Applications/Claude Notify.app/Contents/MacOS/claude-notify" "$title" "$1" ||
      osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title (item 2 of argv)' -e 'end run' "$1" "$title"
  else
    notify-send "$title" "$1"
  fi
}

finish() {
  local topic
  if watching; then
    put @claude idle
  else
    put @claude "done"
    topic=$(get pane_title | sed 's/^[^[:alnum:]]* //')
    notify "Done${topic:+ · $topic}"
  fi
}

# Prints ended, background or blocked, from what Claude Code writes to the transcript after this stop.
# Prints nothing if no marker shows up in about 5 seconds.
turn_outcome() {
  local i marks summaries=0
  for ((i = 0; i < 20; i++)); do
    sleep "${CLAUDE_TMUX_STATE_POLL:-0.25}"
    marks=$(tail -n +"$((lines + 1))" "$transcript" 2>/dev/null | jq -r 'select(.type == "system")
      | if .subtype == "turn_duration" then (if (.pendingBackgroundAgentCount // 0) > 0 then "background" else "ended" end)
        elif .subtype == "stop_hook_summary" then "summary" else empty end' 2>/dev/null || true)
    case $marks in
      *ended*) echo ended; return ;;
      *background*) echo background; return ;;
      # turn_duration follows a summary within a millisecond unless a Stop hook blocked.
      *summary*) ((++summaries < 2)) || { echo blocked; return; } ;;
    esac
  done
}

case $verb in
  off) tmux set -pu -t "$pane" @claude ;;
  idle) put @claude idle ;;
  asking)
    json=$(cat)
    agent=$(field .agent_id)
    put @claude-asker "${agent:-main}"
    ;;
  working)
    if [[ $(get @claude) == blocked ]]; then
      json=$(cat)
      blocker=$(get @claude-blocker)
      agent=$(field .agent_id)
      # Only the agent that asked, or a new prompt from you, ends a block.
      [[ -z $blocker || $(field .hook_event_name) == UserPromptSubmit || ${agent:-main} == "$blocker" ]] || exit 0
    fi
    put @claude working
    ;;
  blocked)
    json=$(cat)
    blocker=""
    [[ $(field .notification_type) == permission_prompt ]] && blocker=$(get @claude-asker)
    put @claude-blocker "$blocker"
    put @claude blocked
    if ! watching; then
      body=$(field .message)
      notify "${body:-Claude needs your input}"
    fi
    ;;
  done) finish ;;
  stop)
    [[ $(get @claude) == blocked ]] && exit 0 # a subagent's prompt is still open
    json=$(cat)
    transcript=$(field .transcript_path)
    lines=$(wc -l 2>/dev/null <"$transcript" || echo 0)
    put @claude stopping
    outcome=$(turn_outcome)
    [[ $(get @claude) == stopping ]] || exit 0 # another event arrived during the hold
    case $outcome in
      blocked) ;;
      background) put @claude working ;;
      *) finish ;;
    esac
    ;;
esac
