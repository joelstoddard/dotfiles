# AWS Region Globe Icon — Design

**Date:** 2026-04-20
**File touched:** `.config/oh-my-posh/theme.yaml` (AWS tooltip segment)
**Source TODO:** `TODO.md` → "Globe icon matching current region"

## Goal

Replace the `-` separator in the AWS right-prompt tooltip with a Nerd Font
globe glyph that visually reflects the AWS region's continent.

## Current behavior

The `aws` tooltip in `theme.yaml` currently renders as:

```
 󰸏 {profile} - {region}
```

Template:

```yaml
template: " 󰸏 {{.Profile}}{{if .Region }} - {{ .Region }}{{end}}"
```

## Target behavior

```
 󰸏 {profile}  {region}
```

The globe glyph varies by region prefix.

## Region-prefix → glyph mapping

| Prefix(es)            | Meaning                                 | Glyph | Code point |
|-----------------------|-----------------------------------------|-------|------------|
| `us-`, `ca-`, `sa-`   | Americas (incl. GovCloud, `us-iso*`)    |     | U+EE46     |
| `eu-`                 | Europe                                  |     | U+EF4B     |
| `ap-`, `cn-`          | Asia-Pacific / China                    |     | U+EE47     |
| `af-`, `me-`, `il-`   | Africa + Middle East                    |     | U+EE45     |
| *anything else*       | Fallback (generic globe)                | 󰇧    | U+F01E7    |

**Rationale for Middle East → Africa:** the  (U+EE45) glyph visually
contains most of the Middle East, more so than the Europe or Asia glyphs.
EMEA-style grouping is also familiar in enterprise contexts.

**Why a distinct fallback glyph:** if AWS introduces a region prefix we haven't
mapped, showing a neutral globe (󰇧) is more discoverable than silently
defaulting to one of the four continents.

## Template

```yaml
template: " 󰸏 {{.Profile}}{{if .Region }} {{ if or (hasPrefix .Region \"us-\") (hasPrefix .Region \"ca-\") (hasPrefix .Region \"sa-\") }}{{ else if hasPrefix .Region \"eu-\" }}{{ else if or (hasPrefix .Region \"ap-\") (hasPrefix .Region \"cn-\") }}{{ else if or (hasPrefix .Region \"af-\") (hasPrefix .Region \"me-\") (hasPrefix .Region \"il-\") }}{{ else }}󰇧{{ end }} {{ .Region }}{{end}}"
```

## Risks & mitigations

- **PUA glyphs render as blank in Claude's Read tool.** The YAML must be
  round-tripped through a byte-level check (`od -c` or a Python ordinal dump)
  after every edit to confirm code points U+EE45, U+EE46, U+EE47, U+EF4B,
  U+F01E7 are preserved. This is called out in `CLAUDE.md`.
- **Tooltip cache.** Oh-my-posh only re-renders the tooltip when the tip command
  (`aws`) is typed at the prompt. Changes won't appear mid-prompt.
- **YAML escaping.** The template is a single double-quoted YAML string;
  `hasPrefix` arguments are `\"…\"`. Any unescaped `"` will break YAML parsing.

## Validation

Manual check only — no automated prompt-rendering tests exist.

1. Set `AWS_PROFILE` and `AWS_REGION=us-east-1`, type `aws ` → expect  glyph.
2. Repeat for `eu-west-1` → , `ap-southeast-2` → ,
   `me-central-1` → , `af-south-1` → , and an invented value like
   `zz-test-1` → 󰇧.
3. `od -c .config/oh-my-posh/theme.yaml | grep -A1 globe` or a Python ordinal
   dump of the tooltip line to confirm glyph bytes are intact.

## Out of scope

- Other TODO items in the "Context-aware icons" block (Terraform, Kubernetes,
  Docker, etc.) — tracked separately.
- A separate oh-my-posh segment for region (staying inside the existing `aws`
  tooltip keeps the change minimal).
