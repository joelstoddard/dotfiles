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
| `working` | `UserPromptSubmit`, `PostToolUse`; a stop that leaves background agents running |
| `stopping` | `Stop`, while the hold below decides whether the turn really ended |
| `blocked` | `Notification`: `permission_prompt`, `elicitation_dialog`, `agent_needs_input` |
| `done` | the end of the hold, `StopFailure` (turn ended on an API error), or `idle` if you are looking at the pane |
| unset | `SessionEnd` |

The window glyph is the highest-priority state among its panes: blocked > done >
working or stopping > idle. tmux lists the pane states with `#{P:#{@claude} }` and
tests the list with `#{m:*blocked*,…}`. The spinner picks a frame from
`#{e|m|:%S,6}`, so it needs no background process, only `status-interval 1`.

Each glyph sets only its colour, so it takes its window's brightness: dim on inactive
windows, as the plain dots are, and full on the current one. A flake check
(`claude-glyph`) fails if the format sets an attribute again.

## Holding "Done" until the turn has ended

Another `Stop` hook can block the stop (the recording plugin's findings-gate does), and Claude
then carries on. No hook event says so, and Claude can think for many seconds before
its next tool call, so waiting for the next event cannot tell a real end from a blocked
one. The session transcript can: Claude Code writes `system/stop_hook_summary` after the
`Stop` hooks, then `system/turn_duration` within a millisecond if the turn ended. A
blocked stop gets the summary with no `turn_duration`.

So `Stop` runs `claude-tmux-state stop` as an `async` hook, which marks the pane
`stopping` and polls the transcript lines written after it, every 0.25s for up to 5s:

- `turn_duration` → the turn ended: `done` and a notification.
- `turn_duration` with `pendingBackgroundAgentCount` above 0 → `working`, without a
  notification. Claude resumes on its own when the agents report back.
- a summary without `turn_duration` on the next poll → blocked: the pane stays
  `stopping` until Claude's next event.
- nothing within 5s → `done` and a notification. A transcript format change degrades
  to an early notification, never to a missing one.

If the pane has left `stopping` by the end of the hold, nothing fires, so two stops in
quick succession notify once. `StopFailure` skips the hold: an API error is an end.

## Which agent is blocked

A subagent's permission prompt blocks the pane like the main session's, but the
`Notification` for it has no `agent_id`, and it fires about 6s after the prompt
appears. `PermissionRequest` fires as the prompt appears and carries the asking
agent's `agent_id` (none for the main session). So `asking` records the asker in
`@claude-asker`, and a `permission_prompt` notification copies it into
`@claude-blocker`. Other dialogs record no blocker.

While a pane is `blocked`, only a `PostToolUse` from the blocker, or a new prompt
(`UserPromptSubmit`), sets it back to `working`. Another agent's tool calls, or a
`Stop` from the main session while a background subagent waits on a prompt, leave it
red.

## Notification title

A notification's title is the session's custom title: the name that `/rename` or
`--name` sets. Only the Claude Notify app shows Claude's icon, so the `osascript` and
`notify-send` titles start with `Claude · `. Hooks get the name as `session_title`. The docs give
it only to `SessionStart`, but Claude Code 2.1.289 also sends it with
`UserPromptSubmit`, so a `/rename` shows from the next prompt.

- `idle` (`SessionStart`) copies it into the pane option `@claude-title`. It writes an
  empty value if the session has no custom title, so a resumed session with no name
  does not keep the name of the last session in that pane.
- `working` updates it only when the field is present, because `PostToolUse` does not
  carry it.
- With no custom title, the title is the tmux `session:window`. The title Claude
  generates for a session it was not given a name for does not reach hooks.

## Choices

- **Always exit 0.** A `Stop` hook that exits 2 keeps Claude from stopping, and a
  broken notifier must never do that.
- **Synchronous hooks with a 5s timeout, except `Stop`.** Async hook runs can finish
  out of order, so a late `working` could overwrite `done`. The `Stop` hold is async so
  that Claude never waits on it, and its final state check stops it from overwriting a
  newer event.
- **Notify unless you are looking at it.** "Looking" means a client with the
  `focused` flag shows this pane (`list-clients -F '#{client_flags} #{pane_id}'`).
- **Notification text goes in as arguments.** The message can contain commands
  Claude wrote, so it is never interpolated into AppleScript.
- **Each hook command starts with `[ -z "$TMUX_PANE" ] ||`.** Claude outside tmux
  (an IDE, the desktop app) may run with a PATH that lacks the script, and must stay
  silent rather than report a hook error on every tool call.

## Setup

On macOS the notifications come from `~/Applications/Claude Notify.app`, listed as
Claude Code in System Settings → Notifications, so they carry Claude's icon. Each
Home Manager switch builds it from `home/files/claude/claude-notify.swift` with the
system `swiftc`, takes the icon from `/Applications/Claude.app`, and signs it ad hoc.
No Nix build compiles the Swift, so the macOS CI job builds it and runs
`test/unit/test_claude_notify.sh`. A post needs a logged-in user, so CI checks only that a
launch without a title and body exits 64.
If the app is missing or refused, the hook falls back to `osascript`, whose
notifications show Script Editor's icon. If none appear at all, allow Script Editor
there.

Why an app, built outside the store:

- `osascript` notifications always show Script Editor's icon. An applet with another
  icon uses the legacy notification API, which macOS 26 refuses to an app it has not
  already allowed. terminal-notifier 2.0.0 does not find Notification Center on
  macOS 26, and posts nothing.
- usernoted refused the same bundle from a temporary directory, and accepted it from
  `~/Applications`. A bundle in the Nix store was not tried.
- The icon exists only inside Claude.app, so it cannot be in the store.

## Known limits

- Esc and Ctrl+C fire no hook, and Claude's pane title does not change on an
  interrupt either. A spinner or red glyph left by an interrupt clears on the next
  prompt in that pane. Intercepting the keys in tmux was rejected as too invasive.
- The hold reads Claude Code's transcript, whose format is internal and can change.
  If the markers disappear, "Done" comes 5s after every stop and a blocked stop
  notifies again.
- A `Stop` hook that takes longer than 5s outlasts the hold, which then notifies.
- If two agents wait on permission prompts at once, the blocker is the one that asked
  last.
- tmux-continuum's auto-save job lives in `status-right`, so `status-interval 1`
  starts it every second. The job exits at once until its save interval passes.
- On a zoomed window the Claude colour replaces the zoom orange.
- Clicking a macOS notification does nothing.
- If Claude Code stops sending `session_title` with `UserPromptSubmit`, a `/rename`
  shows only after the session is resumed.
