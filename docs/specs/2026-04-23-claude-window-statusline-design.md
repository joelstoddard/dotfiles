# Claude Window Statusline — Design

**Date:** 2026-04-23
**File touched:** `.config/oh-my-posh/claude.yaml` (Claude Code `/statusline`)

## Goal

Show team-plan rate-limit windows in the Claude Code statusline so usage vs.
elapsed time is visible at a glance. Having moved from API billing to a team
plan, the two relevant signals are the 5-hour rolling window and the 7-day
window — not context or cost.

## Target appearance

One extra pair of segments prepended to the second prompt block. Reads left
to right, window-first:

```
5h  ██▒│▒▒▒▒▒▒▒ 36% → 4h06m  |  7d  ██████│███▒ 65% → 3d18h  |  󰯉  ████▒▒▒▒▒▒ 40%  |  $0.21  |  Opus
```

### Dual-progress bar encoding

10 cells wide, same width as the existing `󰯉` context bar:

| Symbol | Code point | Meaning                         |
|--------|------------|---------------------------------|
| `█`    | U+2588     | used cell (`floor(usage/10)`)   |
| `▒`    | U+2592     | unused cell                     |
| `│`    | U+2502     | elapsed-time marker (overlays) |

Reading rule: if `│` sits **right of** the fill, pace is fine; if the fill has
reached or passed `│`, the window is being consumed faster than wall-clock.

Choice of U+2502 (box-drawings light vertical) over ASCII `|`: same monospace
width as the block glyphs, same visual weight as `▒`, reads as a line rather
than punctuation. Nerd Font coverage is already assumed by the existing theme
so there is no rendering risk.

## Data sources

All from oh-my-posh's native `claude` segment — no external tool, no script.

| Field                                    | Source                                      |
|------------------------------------------|---------------------------------------------|
| Usage % (5h)                             | `.RateLimits.FiveHour.UsedPercentage`       |
| Usage % (7d)                             | `.RateLimits.SevenDay.UsedPercentage`       |
| Window-end epoch (5h)                    | `.RateLimits.FiveHour.ResetsAt` (unix sec)  |
| Window-end epoch (7d)                    | `.RateLimits.SevenDay.ResetsAt` (unix sec)  |

### Derived values

- **Seconds remaining** = `ResetsAt − now.Unix`
- **Elapsed %**         = `100 × (windowLen − remaining) / windowLen`
  - `windowLen` = `18000` (5h) or `604800` (7d)
- **Remaining formatted**
  - 5h: `printf "%dh%02dm" (div $r 3600) (div (mod $r 3600) 60)`
  - 7d: `printf "%dd%dh" (div $r 86400) (div (mod $r 86400) 3600)`

### Per-cell render rule (inside the `range $i, $_ := until 10`)

```
if   $i == $elapsedCell      → │
elif $i <  $usageCell        → █
else                          → ▒
```

The `│` overrides the fill at its position. If usage has blown past the
elapsed marker the fill still shows; the `│` just sits on top of a `█` cell.

## Placement & styling

- Both new segments are `type: claude`, `style: plain`, `foreground: "#D97757"`
  (matches the existing context/cost/model orange).
- Inserted at the start of the second prompt block in `claude.yaml`, before
  the existing context-bar segment.
- Inline ` |  ` separators follow the existing pattern on cost and model.

## Template pattern (reference; exact form decided during implementation)

```yaml
- type: claude
  style: plain
  foreground: "#D97757"
  template: '5h {{ $u := .RateLimits.FiveHour.UsedPercentage | atoi }}{{ $r := sub .RateLimits.FiveHour.ResetsAt now.Unix }}{{ $e := div (mul (sub 18000 $r) 100) 18000 }}{{ $uc := div $u 10 }}{{ $ec := div $e 10 }}{{ range $i, $_ := until 10 }}{{ if eq $i $ec }}│{{ else if lt $i $uc }}█{{ else }}▒{{ end }}{{ end }} {{ $u }}% → {{ printf "%dh%02dm" (div $r 3600) (div (mod $r 3600) 60) }}'
```

The 7-day segment mirrors this with `SevenDay`, `604800`, and the `%dd%dh`
format.

## Risks & verification

- **`now.Unix` availability.** oh-my-posh templates evaluate via `text/template`
  + sprig. `now` returns `time.Time`; `.Unix` is a method call. Needs a smoke
  test: if `now.Unix` does not resolve, fall back to whatever time helper
  oh-my-posh does expose (sprig `date` funcs, or a static "seconds since
  epoch" helper). This is the only material unknown.
- **Integer division edge cases.** With `$u = 100` and cell width 10, `$uc`
  becomes 10 and the `range … until 10` loop still produces 10 cells — the
  full bar is filled, and the marker at cell 10 (if elapsed also hit 100) is
  simply beyond the loop and not rendered. Acceptable: at 100%/100% the window
  is reset-imminent anyway.
- **Unicode integrity.** `│` (U+2502), `█` (U+2588), `▒` (U+2592) are all BMP
  glyphs, not PUA — Read tool renders them correctly, no `od -c` round-trip
  needed (unlike the Nerd-Font PUA glyphs in `theme.yaml`).
- **YAML quoting.** Templates are single-quoted YAML strings. The existing
  context-bar template uses this form, so no new quoting issues.

## Non-goals (explicit YAGNI)

- **Off-peak countdown** (screenshot has `∇ off-peak 17h06m`). Not natively
  exposed; would require hardcoding Anthropic's off-peak schedule, which is
  fragile.
- **Session timer** (`⏱ 38m 4s`). Not asked for.
- **Color escalation** when usage > elapsed. The `│` marker already makes
  pace visible; color shifts can follow if the visual isn't signal enough in
  practice.
- **Sharing via dev-commons.** Originally scoped but withdrawn. Personal
  dotfiles only for now.

## Validation

Manual — no automated statusline rendering tests exist.

1. Open a Claude Code session; confirm both new segments render before the
   `󰯉` context bar.
2. Observe across a session (or construct a mock `RateLimits` payload if
   possible) that the `│` marker position tracks wall-clock, and the `█`
   fill tracks `UsedPercentage`.
3. Edge cases:
   - Fresh window (0% used, 0% elapsed): `│` at cell 0, no fill.
   - Late window (e.g. 90% elapsed): `│` at cell 9, fill wherever usage is.
   - Usage > elapsed (pace warning): fill extends past `│`, which is still
     visible atop a `█`.
