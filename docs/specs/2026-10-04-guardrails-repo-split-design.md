# Guardrails repo split: three self-contained plugins in `joelstoddard/guardrails`

Tracks issue #134.

## Problem

The `guardrails` plugin lives inside this repo at `.claude/marketplace/plugins/guardrails`,
in a marketplace named `personal`. The personas (`.claude/agents/`) and the rules that
drive them (`.claude/rules/core.md`, `delegation.md`) sit beside it, outside the plugin.
That layout has three costs:

- **Not reusable.** The content is generic on purpose, but the only way to install it is
  to clone the dotfiles. The marketplace is registered per machine as a local
  `directory` source in `.claude/settings.local.json`.
- **One plugin, many jobs.** 16 skills and 12 hooks cover git workflow, code-quality
  warnings, decision records, findings, and lessons. `guardrails@personal` names none of
  them, and `guardrails@guardrails` would be no better.
- **Coupled to the dotfiles.** The personas and `core.md` are linked into `~/.claude/` by
  `home/claude.nix`, so the plugin's skills and hooks assume files a plugin cannot ship.

## Decisions

| Decision | Choice | Why |
|---|---|---|
| Repo | Public `joelstoddard/guardrails`; marketplace `name: "guardrails"` | Generic on purpose, installable without the dotfiles |
| Purpose of the split | Organise by responsibility, wire with `dependencies` | The only consumers are the user's machines. Do not design for outside adopters yet, but keep each plugin installable on its own |
| Plugins | `building`, `recording`, `personas` | One job each. Names describe the job, so `/building:commit` and `/recording:adr` read as what they do |
| Standing rules | Each plugin injects its own rules from `SessionStart` AND `SubagentStart` hooks | Plugins cannot ship `CLAUDE.md` or `.claude/rules/` files. Hook output reaches context, as ponytail and `nbl-guardrails` already do |
| Hook output cap | Every injected file under 10,000 characters, enforced by a test | Hook output over 10,000 characters is saved to a file, and Claude sees only a 2,000-character preview. `core.md` is 15,626 |
| Path-scoped rules | Stay in the dotfiles (`.claude/rules/*.md` with `paths:`) | Plugins have no path-scoped equivalent; they also serve the main session when it edits matching files |
| Personal context | Stays in the dotfiles as an unscoped `.claude/rules/context.md` | The `~/work` convention is the user's, not the plugin's |
| Shared code | Each group of hooks that shares `lib/` lands in one plugin | No symlinks or duplicated helpers needed |
| Versions | No `version` field; `autoUpdate: true` on the marketplace entry | Every push to `main` reaches each machine at the next session. Versions and `<plugin>--v<version>` tags can be added when an outside user needs pinning |
| Validation | `claude plugin validate --strict` in CI | The current plugin has 12 warnings (unquoted `${CLAUDE_PLUGIN_ROOT}` in `hooks.json`); the move fixes them and the gate keeps them fixed |
| History | `git filter-repo` from a clone of the dotfiles, then a restructure commit | Keeps `git log`/`blame` for every moved file |
| Cut-over | One dotfiles PR disables `guardrails@personal` and enables the three new plugins | Plugin hooks have no namespace, so both enabled at once runs every hook twice. One PR reverts in one step |
| Work layer | `nbl-guardrails` stands alone and overrides "any other" RFC/ADR/post-mortem skill | Done separately (`nbl-guardrails` 0.2.1); it names nothing from this plugin, so the renames do not break it |
| `pre-pr-check` + `pre-pr-review` | Merge AFTER the move, as its own change | Keeps the move a pure move |

## Design

### Repo layout

```
.claude-plugin/marketplace.json      # name "guardrails", three relative-path entries
plugins/
  building/
    .claude-plugin/plugin.json
    skills/  hooks/  lib/  rules/  tests/
  recording/
    .claude-plugin/plugin.json
    skills/  hooks/  lib/  rules/  tests/
  personas/
    .claude-plugin/plugin.json       # "dependencies": ["building"]
    agents/  hooks/  rules/  tests/
docs/design/  docs/specs/            # the docs cited from plugin code
.github/workflows/test.yml
README.md
```

The marketplace entry name and each manifest `name` are identical, so the install key
(`building@guardrails`) and the namespace (`building:`) never diverge.

### What goes where

| Plugin | Skills | Hooks | `lib/` | Injected rules |
|---|---|---|---|---|
| `building` | commit, rebase, stacked-diffs, draft-pr, ci-watch, pre-pr-check, pre-pr-review, concise-comments, biases, use-venv | guard-publish, allow-gh-api-read, guard-default-branch, lint-warn, test-gate, post-merge-cleanup, comment-warn, suppression-warn | git-cmd, publish-cmd, shell-split, repo-cmd | `conduct.md`, `engineering.md` |
| `recording` | adr, rfc, mistakes, track-findings, project-memory, self-improvement | findings-capture, findings-gate, lessons-nudge | findings | `findings.md` |
| `personas` | — | persona-report | — | `delegation.md` |

`personas` depends on `building` because every persona assumes the conduct and
engineering rules are loaded. `recording` and `building` stand alone; their skills name
each other only in prose (`pre-pr-review` mentions `concise-comments`, `self-improvement`
mentions `commit` and `draft-pr`), which needs no dependency.

### Rules: from `core.md` to injected files

| Source (`core.md` / `delegation.md`) | Destination | Approx. size |
|---|---|---|
| How to read these rules, minus "Personal and work context"; Agent Conduct minus Findings and Continuity; Security & Data | `building/rules/conduct.md` | 6.5k |
| Design & Architecture, Implementation, Testing & Quality, Version Control, Collaboration & Process | `building/rules/engineering.md` | 7.5k |
| Findings, Continuity, and the document/tracker defaults from "Personal and work context" | `recording/rules/findings.md` | 1.5k |
| `delegation.md` | `personas/rules/delegation.md` | 3.9k |
| The rest of "Personal and work context" (the `~/work` convention) | dotfiles `.claude/rules/context.md` | <1k |

The rules keep PERSONAL and WORK as concepts, but the plugin no longer says how to tell
them apart. It says: "A project is WORK when your context says so; otherwise PERSONAL."
The dotfiles' `context.md` supplies "A project under `~/work` is WORK." The document and
tracker defaults keep their override clause ("WHEN the session context names other skills
OR another tracker, use those"), which is the hook `nbl-guardrails` uses.

Each `hooks.json` injects its rules inline, with no script, one entry per event and file:

```json
{ "type": "command", "timeout": 10,
  "command": "jq -Rs '{hookSpecificOutput:{hookEventName:\"SessionStart\",additionalContext:.}}' \"${CLAUDE_PLUGIN_ROOT}/rules/conduct.md\"" }
```

Each file is its own hook entry, because the 10,000-character cap applies per hook
output, not per event. A missing `jq` fails the hook visibly rather than silently
dropping the rules.

### Renames

- Skills: `guardrails:<skill>` becomes `building:<skill>` or `recording:<skill>`, as listed
  above. This covers skill bodies, hook messages (`comment-warn` names
  `concise-comments`; `findings-gate` names `track-findings`; `lessons-nudge` names
  `self-improvement`), and the injected rules.
- Agents: plugin agents are namespaced, so `architect` becomes `personas:architect`.
  `delegation.md` and the agents' own text stop pointing at `~/.claude/agents/` and
  `~/.claude/rules/core.md`, and name the injected rules instead.
- `persona-report`'s `SubagentStop` matcher currently lists bare names
  (`architect|data-engineer|…`). The name a plugin agent reports to that hook is not
  documented. Spike before relying on it: run one persona with a hook that logs its
  input, then set the matcher to what it reports.
- Personas that read a path-scoped rule (architect, data-engineer, qa-engineer,
  release-engineer, technical-writer) read it IF it exists under `~/.claude/rules/`. Those
  rules stay in the dotfiles, so outside the dotfiles each persona works without them.

### History migration

On a fresh clone of the dotfiles:

```bash
git filter-repo \
  --path .claude/marketplace/ --path .claude/agents/ \
  --path .claude/rules/core.md --path .claude/rules/delegation.md \
  --path docs/design/agent-doc-command-extraction.md \
  --path docs/design/gh-api-read-allow.md \
  --path docs/design/git-command-parsing.md \
  --path docs/specs/2026-09-07-guardrails-autonomy-design.md \
  --path docs/specs/2026-10-02-personas-design.md \
  --path-rename .claude/marketplace/:'' \
  --path-rename .claude/agents/:plugins/personas/agents/ \
  --path-rename .claude/rules/:rules/
```

Then ordinary commits, each reviewable on its own: split `plugins/guardrails/` into
`building/` and `recording/`, split the rules, apply the renames, inject the rules, and
add CI. The personas spec's "Where personas live" decision is overturned by this spec;
update that row in the moved copy rather than keeping two versions.

### Dotfiles after the cut-over

- `.claude/user-settings.json`: add `extraKnownMarketplaces.guardrails`
  (`{"source": "github", "repo": "joelstoddard/guardrails"}`, `autoUpdate: true`); enable
  `building@guardrails`, `recording@guardrails` and `personas@guardrails`; remove
  `guardrails@personal`; rename the `Skill(guardrails:…)` permission rules.
- Delete `.claude/marketplace/`, `.claude/agents/`, `.claude/rules/core.md`,
  `.claude/rules/delegation.md`, and the moved docs. Add `.claude/rules/context.md`.
- `home/claude.nix`: drop the `~/.claude/agents` link. Keep the `~/.claude/rules` link.
- `.claude/CLAUDE.md`, the dotfiles `CLAUDE.md` and the path-scoped rules: rename
  `guardrails:*` references. The `CLAUDE.md` test command loses the plugin suite.
- `.github/workflows/test.yml`: drop the plugin test step.
- `home/git.nix:50`: cite the autonomy spec by its URL in the new repo.
- `test/unit/test_personas.py`: the agent, matcher and skill-name checks move to the new
  repo. What stays checks the rules left here: scoped rules have string `paths:`, and
  `context.md` is the only unscoped rule.
- Each machine, once: `claude plugin marketplace remove personal`.

### Developing the plugins

`claude --plugin-dir ~/personal/guardrails/plugins` loads all three from the checkout,
in place. A `--plugin-dir` plugin replaces the installed plugin with the same name for
that session, so edits are live after `/reload-plugins` with no push.

### Failure modes

| Failure | Effect | Mitigation |
|---|---|---|
| A rules file grows past 10,000 characters | Claude sees a 2,000-character preview | Size test fails in CI |
| `jq` missing | Rules hook errors, visibly | Same dependency the existing hooks already have |
| Old and new plugins enabled together | Every hook runs twice | Cut-over is one PR; `claude plugin list` checked after `home-manager switch` |
| Auto-update ships a broken commit | Every machine gets it at next session | CI gates `main`; `--plugin-dir` testing before push; revert fixes forward |
| `personas` installed without `building` | Personas lack core rules | `dependencies: ["building"]` installs it; agents still STOP and return BLOCKED if the rules are absent |

## Verification

New repo, in CI:

- Each plugin's shell test suite (ported unchanged, then renamed references).
- `claude plugin validate --strict` on the marketplace and each plugin.
- A size test: every file under `plugins/*/rules/` is under 10,000 characters.
- A rules-hook test: each rules hook command, run against a fake `CLAUDE_PLUGIN_ROOT`,
  emits JSON whose `additionalContext` equals the file.
- A reference test: every `building:`, `recording:` and `personas:` name in the repo
  resolves to an existing skill or agent, and no `guardrails:` name remains.

By hand, once:

- The `SubagentStop` spike above, before the matcher is final.
- After the cut-over and `home-manager switch`: `claude plugin list` shows the three
  plugins loaded and `guardrails@personal` gone; a fresh session lists `building:*` and
  `recording:*` skills and `personas:*` agents; a persona run sees the conduct rules.

Dotfiles: `bash test/unit/run.sh` and `nix flake check --no-build` pass.

## Out of scope

- Merging `pre-pr-check` and `pre-pr-review` (an issue in the new repo, after the move).
- Versioned releases, tags, and a bundle plugin.
- Docs for outside adopters beyond a README.
- claude.ai and Cowork support.
- Creating and pushing the public repo happens only on the user's explicit approval at
  that step.
