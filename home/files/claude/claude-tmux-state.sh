# shellcheck shell=bash
# Claude Code hook: records this pane's Claude state in tmux, and notifies when it needs you.
# Usage: claude-tmux-state idle|working|blocked|done|off  (hook JSON on stdin)
# See docs/design/claude-tmux-state.md
set -euo pipefail
trap 'exit 0' EXIT # never fail the hook: exit 2 from Stop keeps Claude running

state=${1:-}
pane=${TMUX_PANE:-}
[[ -n $pane ]] || exit 0

watching() { # a focused client is showing this pane
  grep -q "focused.* $pane\$" <<<"$(tmux list-clients -F '#{client_flags} #{pane_id}')"
}

notify() {
  local title body topic
  title="Claude · $(tmux display -p -t "$pane" '#{session_name}:#{window_index}')"
  if [[ $state == blocked ]]; then
    body=$(jq -r '.message // empty' 2>/dev/null || true)
    body=${body:-Claude needs your input}
  else
    topic=$(tmux display -p -t "$pane" '#{pane_title}' | sed 's/^[^[:alnum:]]* //')
    body="Done${topic:+ · $topic}"
  fi
  # Arguments only: the text can hold commands Claude wrote.
  if [[ $(uname) == Darwin ]]; then
    osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title (item 2 of argv)' -e 'end run' "$body" "$title"
  else
    notify-send "$title" "$body"
  fi
}

case $state in
  off) tmux set -pu -t "$pane" @claude ;;
  idle | working) tmux set -p -t "$pane" @claude "$state" ;;
  blocked | done)
    if watching; then
      [[ $state == blocked ]] || state=idle
      tmux set -p -t "$pane" @claude "$state"
    else
      tmux set -p -t "$pane" @claude "$state"
      notify
    fi
    ;;
esac
