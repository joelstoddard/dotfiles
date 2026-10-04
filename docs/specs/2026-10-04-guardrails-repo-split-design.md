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
| Personal context | The `~/work` convention stays in the dotfiles as an unscoped `.claude/rules/context.md` | It is the user's convention, not the plugin's |
| Shared code | Each group of hooks that shares `lib/` lands in one plugin | No symlinks or duplicated helpers needed at runtime |
| Versions | No `version` field; `autoUpdate: true` on the marketplace entry | Every push to `main` reaches each machine at the next session, with no bump to forget |
| Validation | `claude plugin validate --json` in CI, failing on any error or any warning except the missing `version` | `--strict` rejects a plugin with no `version`, so it cannot coexist with the decision above. The current plugin's 12 warnings (unquoted `${CLAUDE_PLUGIN_ROOT}`) still fail the filter, so the move must fix them |
| Plugin dependencies | `personas` depends on `building` AND `recording` | Personas assume the conduct and engineering rules, file findings under recording's Findings rule, and default to its `rfc`, `adr` and `mistakes`; `findings-capture` parses the persona report |
| Tests | One repo-root `tests/` with a single helper and runner | Tests stay out of the plugins, so they are not copied into the plugin cache, and the helper is not duplicated |
| History | `git filter-repo` from a clone of the dotfiles, then restructure commits | Keeps `git log --follow` for every moved file, including its earlier paths |
| Cut-over | Ordered steps below; one dotfiles PR swaps the plugins | Plugin hooks have no namespace, so both enabled at once runs every hook twice |
| Work layer | `nbl-guardrails` stands alone and overrides "any other" RFC/ADR/post-mortem skill | Done separately (`nbl-guardrails` 0.2.1); it names nothing from this plugin, so the renames do not break it |
| `pre-pr-check` + `pre-pr-review` | Merge AFTER the move, as its own change | Keeps the move a pure move |

## Design

### Repo layout

```
.claude-plugin/marketplace.json      # name "guardrails", a description, three relative-path entries
plugins/
  building/    .claude-plugin/plugin.json  skills/  hooks/  lib/  rules/
  recording/   .claude-plugin/plugin.json  skills/  hooks/  lib/  rules/
  personas/    .claude-plugin/plugin.json  agents/  hooks/  rules/
tests/                               # helper.sh, run.sh, and every suite
docs/design/  docs/specs/            # the docs cited from plugin code
AGENTS.md                            # "- **Test:** `bash tests/run.sh`", so building's test gate runs here too
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

Each hook's `lib/` chain stays inside its plugin: `guard-publish` and `allow-gh-api-read`
use `publish-cmd` and `shell-split`; `guard-default-branch` uses `git-cmd` and
`shell-split`; `lint-warn` and `test-gate` use `repo-cmd` and `git-cmd`; the findings
hooks use `findings`.

Dependencies between plugins:

- `personas` declares `"dependencies": ["building", "recording"]`. Every persona assumes
  the conduct and engineering rules. `delegation.md` files persona findings under the
  Findings rule, `technical-writer` and `sre` default to `recording`'s `rfc`, `adr` and
  `mistakes`, and `findings-capture` parses the persona report's "Findings outside
  scope" heading, whose format `delegation.md` defines.
- `building` and `recording` stand alone. Their skills name each other only in prose
  (`adr` mentions `building:concise-comments`; `self-improvement` mentions
  `building:commit` and `building:draft-pr`), which needs no dependency.
- `recording` names two skills from another marketplace: `rfc` runs
  `superpowers:brainstorming`, and `self-improvement` runs
  `superpowers:using-git-worktrees`. Declaring `superpowers` would need
  `allowCrossMarketplaceDependenciesOn: ["claude-plugins-official"]` in
  `marketplace.json`. That is out of scope; the README lists `superpowers` as a
  prerequisite instead.

State files keep their current paths: `$XDG_STATE_HOME/claude-guardrails/findings` and
`~/.claude/skill-lessons.jsonl`. Neither depends on the plugin name, so state carries
across the cut-over. Do not move them to `${CLAUDE_PLUGIN_DATA}` in this change.

### Rules: from `core.md` to injected files

Measured with the current files:

| Source | Destination | Size |
|---|---|---|
| The intro (rewritten without paths); How to read these rules, minus the `~/work` convention; Agent Conduct minus Findings and Continuity; Security & Data | `building/rules/conduct.md` | ~6.5k |
| Design & Architecture, Implementation, Testing & Quality, Version Control, Collaboration & Process | `building/rules/engineering.md` | ~7.5k |
| Findings and Continuity (each keeps its `Tier: EDIT` tag), plus the document and tracker defaults from "Personal and work context" | `recording/rules/findings.md` | ~1.3k |
| `delegation.md` | `personas/rules/delegation.md` | 3.9k |
| "A project under `~/work` is WORK" | dotfiles `.claude/rules/context.md` | <0.5k |

The rules keep PERSONAL and WORK as concepts, but the plugin no longer says how to tell
them apart. It says: "A project is WORK when your context says so; otherwise PERSONAL."
The dotfiles' `context.md` supplies the `~/work` test. The document and tracker defaults
keep their override clause ("WHEN the session context names other skills OR another
tracker, use those"), which `nbl-guardrails` relies on. The ownership bullet
(`core.md:46`, "In a PERSONAL project, the user owns every service… Do NOT ask") stays in
`conduct.md`: it is generic once context defines PERSONAL.

Each `hooks.json` injects its rules inline, with no script: one entry per event and file,
with the event name hard-coded in that entry.

```json
{ "type": "command", "timeout": 10,
  "command": "jq -Rs '{hookSpecificOutput:{hookEventName:\"SessionStart\",additionalContext:.}}' \"${CLAUDE_PLUGIN_ROOT}/rules/conduct.md\"" }
```

`personas`' entries differ in one way: their filter is
`gsub("\\$\\{CLAUDE_PLUGIN_ROOT\\}"; $root)` with `--arg root "${CLAUDE_PLUGIN_ROOT}"`, so
`delegation.md` can name the installed agents directory as
`${CLAUDE_PLUGIN_ROOT}/agents/` and the session sees the real path.

Each file is its own hook entry, because the 10,000-character cap applies per hook
output, not per event. `jq` is installed by `home/packages.nix`. Without it, the hook
exits 127, a non-blocking hook error. Personas would notice the missing rules and STOP;
the main session would not.

### Renames

- **Skills:** `guardrails:<skill>` becomes `building:<skill>` or `recording:<skill>`, as
  listed above. This covers skill bodies, hook messages (`comment-warn` names
  `concise-comments`, `findings-gate` names `track-findings`, `lessons-nudge` names
  `self-improvement`), and the injected rules.
- **Agents:** plugin agents are namespaced, so `architect` becomes `personas:architect`.
- **Paths to files that move:** `~/.claude/rules/core.md`, `~/.claude/rules/delegation.md`
  and `~/.claude/agents/` stop resolving. Every reference names the injected rules
  instead ("the core principles", "the persona report format"). Found by `git grep`:
  - the agents' own text, including bare `core.md` in `qa-engineer.md:12`,
    `release-engineer.md:12` and `security-engineer.md:12`;
  - `delegation.md:20,23,25`;
  - `persona-report.sh:3,20`, whose block message points at `delegation.md`'s path;
  - the dotfiles `.claude/rules/testing.md:15`, which stays behind;
  - `delegation.md:11` tells the orchestrator to read a persona file under
    `~/.claude/agents/`. It becomes `${CLAUDE_PLUGIN_ROOT}/agents/`, which the personas
    rules hook replaces with the installed path.
- **Domain rules:** personas that read a path-scoped rule (architect, data-engineer,
  qa-engineer, release-engineer, technical-writer) read it IF it exists under
  `~/.claude/rules/`. Outside the dotfiles they work without it.
- **`self-improvement apply`:** it edits skill files in a worktree and runs the tests.
  After the move the loaded skills are a read-only cache copy, so `apply` names the
  source checkout (`~/personal/guardrails`). Journal entries are keyed by
  `guardrails:<name>`; `apply` maps each old name to its new plugin. Lines 47 and 69
  call the publish and default-branch guards "the plugin's"; they become `building`'s.
  Line 71 runs "the plugin's test suite"; it becomes the repo's `tests/run.sh`.
- **`persona-report`'s `SubagentStop` matcher:** it lists bare names
  (`architect|data-engineer|…`). The name a plugin agent reports is not documented. No
  new code is needed to find out: `findings-capture.sh` already records `.agent_type`,
  and `findings-gate` prints it. Run one persona that reports one finding, read the
  name, and set the matcher to it. Confirm the matcher handles `-` and `:`.

### History migration

On a fresh clone of the dotfiles (the dotfiles repo is already public, so this exposes no
new history):

```bash
git filter-repo \
  --path .claude/marketplace/ --path .claude/skills/ --path .claude/agents/ \
  --path .claude/rules/core.md --path .claude/rules/delegation.md \
  --path docs/design/agent-doc-command-extraction.md \
  --path docs/design/gh-api-read-allow.md \
  --path docs/design/git-command-parsing.md --path docs/git-command-parsing.md \
  --path docs/specs/2026-09-07-guardrails-autonomy-design.md \
  --path docs/specs/2026-10-02-personas-design.md \
  --path-rename .claude/marketplace/:'' \
  --path-rename .claude/agents/:plugins/personas/agents/ \
  --path-rename .claude/rules/:rules/
```

`.claude/skills/` and `docs/git-command-parsing.md` are the earlier paths of `commit`,
`draft-pr`, `rebase`, `stacked-diffs`, `use-venv`, `review` and the git-parsing doc.
Without them, `git log --follow` stops at the move into the marketplace.

Then ordinary commits, each reviewable on its own:

1. Split `plugins/guardrails/` into `building/` and `recording/`, and remove
   `"version": "0.11.0"` from the manifest and marketplace entry. A leftover version
   would pin every machine to the first install.
2. Split the rules into the files above.
3. Apply the renames.
4. Add the rules hooks, quote every `${CLAUDE_PLUGIN_ROOT}`, and add the tests, `AGENTS.md`
   and CI.
5. Fix the moved docs. The personas spec's "Where personas live" row is overturned by
   this spec, so update it there. Moved docs that cite dotfiles files
   (`gh-api-read-allow.md:8`, the autonomy spec's `home/git.nix` lines, the personas
   spec's `.claude/` paths) link to them in the dotfiles repo on GitHub.

### Dotfiles changes (one PR)

- `.claude/user-settings.json`: add the marketplace, in the nested form the `ponytail`
  entry uses:

  ```json
  "guardrails": { "source": { "source": "github", "repo": "joelstoddard/guardrails" }, "autoUpdate": true }
  ```

  Enable `building@guardrails`, `recording@guardrails` and `personas@guardrails`; remove
  `guardrails@personal`; rename the `Skill(guardrails:…)` permission rules.
- Delete `.claude/marketplace/`, `.claude/agents/`, `.claude/rules/core.md`,
  `.claude/rules/delegation.md`, and the moved docs. Add `.claude/rules/context.md`.
- `home/claude.nix`: drop the `~/.claude/agents` link. Keep the `~/.claude/rules` link.
  Update the comments at lines 37-39 and 43.
- `.claude/CLAUDE.md` and the dotfiles `CLAUDE.md`: rename `guardrails:*` references.
  Rewrite the `CLAUDE.md:21` bullet (agents, rules, `test_personas.py`, the personas
  spec), and drop the plugin suite from the test command and the commands block (`:51`,
  `:64`).
- `.claude/rules/testing.md:15`: name "the core principles", not `core.md`.
- `README.md:141` and `docs/design/claude-settings-split.md:50-56`: replace the
  `personal` marketplace setup step with the `guardrails` marketplace.
- `test/unit/run.sh:2`: drop "Mirrors the guardrails plugin's own runner".
- `.github/workflows/test.yml`: drop the plugin test step.
- `home/git.nix:50`: cite the autonomy spec by its URL in the new repo.
- `test/unit/test_personas.py`: the agent, matcher and skill-name checks move to the new
  repo. What stays checks the rules left here: scoped rules have string `paths:`, and
  `context.md` is the only unscoped rule.
- After merge, update the auto-memory notes that describe `guardrails@personal`.

### Cut-over and rollback

The links in `home/claude.nix` point into the main checkout, so pulling the dotfiles PR
changes `~/.claude/` at once. `home-manager switch` only removes the `agents` link.
Hence a fixed order:

1. Create and push `joelstoddard/guardrails`, only on the user's explicit approval at
   this step. Protect `main` with the CI check required, and wait for CI to pass.
2. On one machine, `claude plugin marketplace add joelstoddard/guardrails` and install
   the three plugins with `--scope user`. Run `claude plugin list` to confirm they load
   alongside the old plugin; for this check only, both sets running is acceptable.
3. Merge the dotfiles PR.
4. On each machine: pull; `claude plugin marketplace remove personal`;
   `home-manager switch`; `claude plugin list` shows the three plugins loaded and no
   `guardrails@personal`. If a plugin is missing, `claude plugin install <name>@guardrails`.
   Restart running sessions.

Rollback, per machine:

1. Revert the dotfiles PR, then pull and run `home-manager switch`.
2. `claude plugin marketplace add --scope local ~/personal/dotfiles/.claude/marketplace`.
   The revert cannot restore this: `marketplace remove` with no `--scope` deletes the
   declaration from every scope, including the gitignored `settings.local.json`.
3. `claude plugin uninstall` any of the three new plugins that `claude plugin list` still
   shows.

### Developing the plugins

`claude --plugin-dir ~/personal/guardrails/plugins` loads all three from the checkout,
in place. A `--plugin-dir` plugin replaces the installed plugin with the same name for
that session, so edits are live after `/reload-plugins` with no push.

### Failure modes

| Failure | Effect | Mitigation |
|---|---|---|
| A rules file grows past 10,000 characters | Claude sees a 2,000-character preview | Size test fails in CI |
| A rules file missing its `SubagentStart` entry | Personas STOP and return BLOCKED | Completeness test fails in CI |
| `jq` missing | Rules hooks exit 127, a non-blocking error | `jq` is in `home/packages.nix`; personas STOP on missing rules |
| Old and new plugins enabled together | Every hook runs twice | Cut-over order; `claude plugin list` checked on each machine |
| Auto-update ships a broken commit | Every machine gets it at the next session | Required CI check on `main`; `--plugin-dir` testing before push; revert fixes forward |
| `personas` installed without `building` or `recording` | Personas lack core or findings rules | `dependencies` installs both; agents STOP and return BLOCKED if the rules are absent |

## Verification

New repo, in CI (the workflow installs `@anthropic-ai/claude-code` from npm, and Python for
the agent checks):

- Every hook test suite, ported into `tests/`, then with renamed references.
- Manifest validation on the marketplace and each plugin. This filter passes a plugin
  whose only warning is the missing `version`, and fails the current plugin on its 12:

  ```bash
  claude plugin validate --json "$target" | jq -e '
    [.. | objects | .errors? // empty | .[]] == [] and
    [.. | objects | .warnings? // empty | .[] | select(.path != "version")] == []'
  ```

  A separate check fails if any `plugin.json` or marketplace entry sets `version`.
- Size test: every file under `plugins/*/rules/` is under 10,000 characters.
- Rules-hook test: every `plugins/*/rules/*.md` has a `SessionStart` AND a
  `SubagentStart` entry in its plugin's `hooks.json`, each with the matching
  `hookEventName`. Each command, run with a fake `CLAUDE_PLUGIN_ROOT`, emits JSON whose
  `additionalContext` equals the file, with `${CLAUDE_PLUGIN_ROOT}` replaced by the fake
  root for `personas`.
- Reference test: every `building:`, `recording:` and `personas:` name resolves to an
  existing skill or agent. The repo has no `guardrails:` names, and no `~/.claude/agents`,
  `~/.claude/rules/core.md`, `~/.claude/rules/delegation.md` or bare `core.md`.
- Agent checks from `test_personas.py`: each agent declares name, description and tools,
  and the `persona-report` matcher lists exactly the agents.
- Skill preamble test across `plugins/*/skills`.

By hand, once:

- The `SubagentStop` spike above, before the matcher is final.
- After cut-over: a fresh session lists `building:*` and `recording:*` skills and
  `personas:*` agents; asked for the last bullet of `engineering.md`, it quotes it, which
  shows the rules arrived in full; a persona run sees the conduct rules.
- Auto-update: push a trivial commit, start a new session, and confirm the plugin's
  version in `~/.claude/plugins/installed_plugins.json` changed.

Dotfiles: `bash test/unit/run.sh` and `nix flake check --no-build` pass.

## Out of scope

- Merging `pre-pr-check` and `pre-pr-review` (an issue in the new repo, after the move).
- Versioned releases, tags, and a bundle plugin.
- Declaring `superpowers` as a cross-marketplace dependency.
- Docs for outside adopters beyond a README.
- claude.ai and Cowork support.
