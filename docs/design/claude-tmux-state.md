# Claude state in tmux

Several Claude sessions run in tmux windows at once. Each window's status glyph says
what its Claudes are doing, and an OS notification fires when one needs you. Issue #129
holds the full design discussion.

## State lives per pane

Claude Code hooks run `claude-tmux-state <state>`, which writes the tmux user option
`@claude` on `$TMUX_PANE`. It is per pane so that two Claudes in one window never
overwrite each other, and tmux drops it when the pane closes.

| State | Set by |
|---|---|
| `idle` | `SessionStart` (startup, resume, clear); focusing a `done` pane (tmux `pane-focus-in`) |
| `working` | `UserPromptSubmit`, `PostToolUse` |
| `blocked` | `Notification`: `permission_prompt`, `elicitation_dialog`, `agent_needs_input` |
| `done` | `Stop`, `StopFailure` (turn ended on an API error), or `idle` if you are looking at the pane |
| unset | `SessionEnd` |

The window glyph is the highest-priority state among its panes: blocked > done >
working > idle. tmux lists the pane states with `#{P:#{@claude} }` and tests the list
with `#{m:*blocked*,…}`. The spinner picks a frame from `#{e|m|:%S,6}`, so it needs no
background process, only `status-interval 1`.

## Choices

- **Always exit 0.** A `Stop` hook that exits 2 keeps Claude from stopping, and a
  broken notifier must never do that.
- **Synchronous hooks with a 5s timeout.** Async hook runs can finish out of order,
  so a late `working` could overwrite `done`.
- **Notify unless you are looking at it.** "Looking" means a client with the
  `focused` flag shows this pane (`list-clients -F '#{client_flags} #{pane_id}'`).
- **Notification text goes in as arguments.** The message can contain commands
  Claude wrote, so it is never interpolated into AppleScript.
- **Each hook command starts with `[ -z "$TMUX_PANE" ] ||`.** Claude outside tmux
  (an IDE, the desktop app) may run with a PATH that lacks the script, and must stay
  silent rather than report a hook error on every tool call.

## Known limits

- Esc and Ctrl+C fire no hook, and Claude's pane title does not change on an
  interrupt either. A spinner or red glyph left by an interrupt clears on the next
  prompt in that pane. Intercepting the keys in tmux was rejected as too invasive.
- `status-interval 1` makes tmux-continuum's status-right save check spawn a
  process every second.
- On a zoomed window the Claude colour replaces the zoom orange.
