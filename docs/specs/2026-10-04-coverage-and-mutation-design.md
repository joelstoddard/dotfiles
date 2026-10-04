# Coverage and mutation testing for the repo's shell code

## Problem

The repo's real logic is shell: about 850 lines of bash in the guardrails plugin
(`lib/` and `hooks/scripts/`), the 104-line `claude-tmux-state` hook script, and about
95 lines of zsh in autoenv. The tests for it are zsh and bash suites run by
`test/unit/run.sh` and the plugin's `tests/run.sh`.

Nothing measures those tests:

- No coverage number. An agent can add a branch to a hook with no test for it, and
  every check stays green.
- No mutation testing. A test can execute a line without asserting on what it does.
  This matters most for the guardrails hooks, which are safety code: `guard-publish`
  and `guard-default-branch` stop agents doing outward-facing things.

The repo rules (`.claude/rules/testing.md`) require a coverage floor and mutation
testing where the project configures them, and flag their absence as findings. Both
were raised as findings during #132 and are resolved by this work.

## Decisions

| Decision           | Choice                                                                                   | Why                                                                                                                                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Role of each       | Coverage blocks PRs from the start. Mutation reports first, and gets a floor later       | Coverage is deterministic, so a ratchet never flakes. A first mutation score includes unkillable equivalent mutants and needs triage before it can gate                                                    |
| Scope              | All shell logic: the guardrails plugin, `home/files/**/*.sh`, autoenv (zsh)              | Covers all the code that has behaviour. The Nix modules are configuration, checked by `nix flake check`                                                                                                    |
| Tooling            | In-repo coverage tracer and in-repo mutator, plain bash and zsh                          | `kcov` is Linux-only in nixpkgs and can't trace zsh. `bashcov` is not packaged. No maintained mutation tool exists for shell. The in-repo tools run on macOS and CI alike, so agents can check before a PR |
| Coverage floor     | Per file and total, starting at today's measured values, in a committed file             | A total alone lets a weak file hide behind well-tested ones. Starting at measured values means no threshold is invented                                                                                    |
| Ratchet            | CI fails if any floor drops below its value on `main`, or vanishes while its file exists | Makes "floors only rise" machine-enforced                                                                                                                                                                  |
| Mutation reporting | A weekly CI run maintains one rolling issue                                              | One issue per survivor would flood the tracker on the first run, mostly with equivalent mutants                                                                                                            |

## Design

### Commands

Both are plain bash under `test/`, and documented as **Coverage** and **Mutation** in
`CLAUDE.md`'s Commands section. The **Test** command, which the guardrails push gate
runs, stays as it is.

- `test/coverage.sh`: runs every suite under tracing and prints per-file and total
  coverage. It exits 1 if a measured file or the total is below its floor, or a measured
  file has no floor. `--update` sets each floor to its current value and never lowers
  one.
- `test/mutate.sh [--changed | FILE…]`: runs mutation testing on all measured files,
  on files changed against `origin/main`, or on the given files, and prints results.

### Measured files

- `home/files/**/*.sh` and `home/files/**/*.zsh`
- `.claude/marketplace/plugins/guardrails/lib/*.sh`
- `.claude/marketplace/plugins/guardrails/hooks/scripts/*.sh`

Trace lines from any other file, including the tests themselves, are ignored.

The suites that run under tracing are `test/unit/test_*.sh`, each run with zsh as
`test/unit/run.sh` does, and `.claude/marketplace/plugins/guardrails/tests/test_*.sh`,
each run with bash as that plugin's `tests/run.sh` does. `test/unit/test_personas.py`
checks documents, not shell, so it stays out.

### Coverage

**Tracing, with no change to tests or scripts.**

- **bash:** `BASH_ENV` names an init file that every non-interactive bash reads. It
  opens a descriptor to the trace log, sets `BASH_XTRACEFD` to it, sets `PS4` to print
  `file:line`, and runs `set -x`. The trace never reaches stdout or stderr, so tests
  that check output or discard stderr are unaffected.
- **zsh:** zsh has no `BASH_XTRACEFD`, and its trace goes to stderr. The intended route
  is a `.zshenv`, behind a temporary `ZDOTDIR`, that installs a `TRAPDEBUG` writing
  `file:line` to the log. This is unproven, so it is the first step of the rollout, a
  spike. If it cannot be done without disturbing stderr or the tests, autoenv appears as
  "not measured" in the coverage report, with no floor, and that exception is documented.
  Mutation testing still covers it.
- **Per-test logs:** each test file runs separately with its own log, so the report
  knows which tests execute which lines. The mutator uses this.

**Executable lines.** Every line of a measured file counts, except:

- blank lines and comment lines;
- lines that hold only `then`, `else`, `fi`, `do`, `done`, `esac`, `;;`, `{` or `}`;
- continuation lines inside multi-line strings and heredocs;
- lines ending in `# coverage: ignore <reason>`. The reason is required, and the
  marker is for unreachable lines only.

The heuristic only needs to be consistent, not exact, because floors start at measured
values and compare like with like.

**Floors.** `test/coverage-floor.tsv` holds one `path<TAB>percent` line per measured
file and a `TOTAL` line. Percentages are rounded down to one decimal place.

**CI.** The `unit` job in `.github/workflows/test.yml` runs `test/coverage.sh`. A
second step fetches `main` and compares `test/coverage-floor.tsv` with its version
there. It fails if any value is lower, or a floor is missing while its file still
exists.

### Mutation

**Mutants.** One mutant per operator match on each **covered** executable line.
Uncovered lines are coverage's problem, so they are counted and not mutated.

| Operator    | Mutation                                                    |
| ----------- | ----------------------------------------------------------- |
| Comparison  | `==`↔`!=`, `-eq`↔`-ne`, `-lt`↔`-ge`, `-gt`↔`-le`, `-z`↔`-n` |
| Logic       | `&&`↔`\|\|`, drop a leading `!`                             |
| Exit status | `exit 0`↔`exit 1`, `exit 2`→`exit 0`, `return 0`↔`return 1` |
| Boolean     | `true`↔`false` as commands                                  |
| Deletion    | a simple command line replaced by `:`                       |

**Running a mutant.**

- **Isolation:** each mutant is applied in a temporary copy of the working tree, never
  the checkout, and reverted before the next one.
- **Test selection:** only the test files whose coverage logs executed the mutated
  line.
- **Timeout:** 10× the selected tests' baseline time. A timeout counts as killed.
- **Red baseline:** if the selected tests fail before any mutation, the run stops with
  an error.

**Results.** Score = killed ÷ (killed + survived), per file and total. Each survivor is
printed as `file:line  operator  original → mutated`.

**Equivalent mutants.** `test/mutants-ignore.tsv` lists mutants that cannot change
behaviour: file, original line text, operator, and a required reason. Entries match by
line text, not line number, so they survive edits elsewhere in the file. Ignored mutants
are left out of the score. Under the testing rules, each survivor gets either a test
that kills it or an ignore entry that justifies it.

**Pre-PR use.** Agents run `test/mutate.sh --changed` on the measured files they
changed, and answer every survivor with a test or an ignore entry. It does not gate on
a score yet.

**Weekly CI.** `.github/workflows/mutation.yml` runs on a weekly schedule and on
`workflow_dispatch`, with `contents: read` and `issues: write` only. It runs the full
set and maintains one open issue labelled `mutation`: survivors grouped by file, with
per-file and total scores. It closes the issue when nothing survives. The issue is
posted by `github-actions`.

**A floor later.** Once a few weekly runs show a stable score, a
`test/mutation-floor.tsv` reuses the coverage ratchet check and turns the score into a
blocking check. That is a separate decision for the user. The mutator's output format
matches coverage's so the same checker applies.

### Tests for the tools

`test/unit/test_coverage_tools.sh` exercises the tools on fixture scripts and fixture
tests in a temporary directory:

- **Tracer:** a fixture with an `if`/`else`, whose test takes one branch, reports
  exactly the lines that branch executed.
- **Heuristic:** `fi`, `done`, comments, heredoc bodies and `# coverage: ignore` lines
  are excluded.
- **Ratchet:** a lowered floor fails, a missing floor fails, and `--update` raises a
  floor but never lowers one.
- **Mutator:** a fixture with one killable and one surviving mutant reports one killed
  and one survivor. An ignore entry removes the survivor from the score, and a mutant
  that hangs counts as killed by timeout.

### Failure modes

All of them fail closed:

- **Tracing stops working** (for example, `BASH_ENV` is no longer read): measured files
  report 0%, fall below their floors, and CI fails.
- **A new measured file:** CI fails with "no floor for FILE" until `--update` records
  one.
- **Red suite:** the mutator refuses to score.
- **zsh tracing unavailable:** autoenv is reported as "not measured", never dropped
  silently.

## Rollout

Stacked PRs, using `guardrails:stacked-diffs`:

1. **zsh tracing spike:** decides how autoenv is measured.
2. **Coverage:** tracer, heuristic, `test/coverage.sh`, tool tests, an initial
   `test/coverage-floor.tsv` from a real run, and the CI step with the ratchet check.
3. **Mutation:** `test/mutate.sh`, `test/mutants-ignore.tsv`, `--changed`, and tool
   tests. The first full run's scores and survivors go in the PR description.
4. **Weekly workflow:** `.github/workflows/mutation.yml` with the rolling issue.

PR 2 creates `docs/design/coverage-and-mutation.md`, which the tools' comments cite,
and adds **Coverage** to `CLAUDE.md`'s Commands. PRs 3 and 4 extend both.

**Implementation:**

- The qa-engineer persona builds 1–3.
- The release-engineer persona adds the CI step in 2 and the workflow in 4, after
  qa-engineer, since they share files.
- The orchestrating session reviews each change and re-runs every check before
  reporting it done.

## Out of scope

- A mutation floor, until weekly runs have settled.
- Coverage or mutation for the Nix modules and the nvim subtree. The subtree is its own
  repo.
- Line-exact coverage. The heuristic aims for consistency.
- Changes to the guardrails pre-PR check beyond what its documented commands pick up.
