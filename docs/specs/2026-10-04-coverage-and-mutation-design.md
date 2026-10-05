# Coverage and mutation testing for the repo's shell code

## Problem

The repo's real logic is shell: the `claude-tmux-state` hook script and the autoenv
zsh, about 220 lines together. The tests for it are the zsh suites run by
`test/unit/run.sh`. The guardrails plugin, about 850 lines of bash, was in this repo
when this spec was written. It moved to `joelstoddard/guardrails` in #151, so it is out
of scope here.

Nothing measures those tests:

- No coverage number. An agent can add a branch to a hook with no test for it, and
  every check stays green.
- No mutation testing. A test can execute a line without asserting on what it does.

The repo rules (`.claude/rules/testing.md`) require a coverage floor and mutation
testing where the project configures them, and flag their absence as findings. Both
were raised as findings during #132 and are resolved by this work.

## Decisions

| Decision           | Choice                                                                                   | Why                                                                                                                                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Role of each       | Coverage blocks PRs from the start. Mutation reports first, and gets a floor later       | Coverage is deterministic, so a ratchet never flakes. A first mutation score includes unkillable equivalent mutants and needs triage before it can gate                                                    |
| Scope              | All shell logic: `home/files/**/*.sh` and `home/files/**/*.zsh`, autoenv included        | Covers all the code that has behaviour. The Nix modules are configuration, checked by `nix flake check`                                                                                                    |
| Tooling            | In-repo coverage tracer and in-repo mutator: bash, zsh, POSIX awk, and perl for timeouts | `kcov` is Linux-only in nixpkgs and can't trace zsh. `bashcov` is not packaged. No maintained mutation tool exists for shell. The in-repo tools run on macOS and CI alike, so agents can check before a PR |
| Coverage floor     | Per file and total, starting at today's measured values, in a committed file             | A total alone lets a weak file hide behind well-tested ones. Starting at measured values means no threshold is invented                                                                                    |
| Ratchet            | CI fails if any floor drops below its value on `main`, or vanishes while its file exists | Makes "floors only rise" machine-enforced                                                                                                                                                                  |
| Mutation reporting | A weekly CI run maintains one rolling issue                                              | One issue per survivor would flood the tracker on the first run, mostly with equivalent mutants                                                                                                            |

## Design

### Commands

Both are bash scripts under `test/`, and documented as **Coverage** and **Mutation** in
`CLAUDE.md`'s Commands section. The **Test** command, which the guardrails push gate
runs, stays as it is.

- `test/coverage.sh`: runs every suite under tracing and prints per-file and total
  coverage. It exits 1 if a measured file or the total is below its floor, or a measured
  file has no floor. `--update` sets each floor to its current value and never lowers
  one. `--files`, `--lines FILE` and `--trace` give the mutator the measured set, the
  executable lines and the per-test hits, so both tools share one definition of each.
- `test/mutate.sh [-j N] [--changed | FILE…]`: runs mutation testing on all measured
  files, on files changed against `origin/main`, or on the given files, with `N`
  parallel workers (by default, one for each CPU), and prints results. It exits 0 when
  it reports, survivors included, 1 on a red suite or a tool error, and 2 on a usage
  error.

### Measured files

- `home/files/**/*.sh` and `home/files/**/*.zsh`

Trace lines from any other file, including the tests themselves, are ignored.

The suites that run under tracing are `test/unit/test_*.sh`, each run with zsh as
`test/unit/run.sh` does. `test/unit/test_rules.py` checks documents, not shell, so it
stays out.

### Coverage

**Tracing, with no change to tests or scripts.**

- **bash:** `BASH_ENV` names an init file that every non-interactive bash reads. It
  opens a descriptor to the trace log, sets `BASH_XTRACEFD` to it, sets `PS4` to print
  `file:line`, and runs `set -x`. The trace never reaches stdout or stderr, so tests
  that check output or discard stderr are unaffected.
- **zsh:** zsh has no `BASH_XTRACEFD`, and its trace goes to stderr. A `.zshenv`, behind
  a temporary `ZDOTDIR`, installs a `TRAPDEBUG` that writes `file:line` to the log. The
  spike that proved this route landed with coverage in #144.
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
Uncovered lines are coverage's problem, so they get no mutants.

| Operator    | Mutation                                                                  |
| ----------- | ------------------------------------------------------------------------- |
| Comparison  | `==`↔`!=`; `-eq`↔`-ne`, `-lt`↔`-ge`, `-gt`↔`-le`, `-z`↔`-n` in a test     |
| Logic       | `&&`↔`\|\|`, drop a leading `!`                                           |
| Exit status | `exit 0`↔`exit 1`, `exit 2`→`exit 0`, `return 0`↔`return 1`               |
| Boolean     | `true`↔`false` as whole words                                             |
| Deletion    | a simple command or assignment line replaced by `:`                       |

Strings and comments get no mutants. The `-n`-style operators change only after `[[`,
`[` or `test` on the line, so options such as `head -n` stay as they are. Deletion
leaves control lines, declarations (`local`, `declare`, `export`, `readonly`) and lines
that open or continue a block, a pipeline or a heredoc alone.

**Running a mutant.**

- **Isolation:** each worker has its own scratch copy of the working tree, never the
  checkout, and restores the mutated file after each mutant.
- **Test selection:** only the test files whose coverage logs executed the mutated
  line. The first one that fails kills the mutant.
- **Timeout:** 10× that test's own baseline time, and at least 2s. A timeout counts as
  killed. Each test runs in its own process group under a small perl wrapper. The
  wrapper kills the group when the test ends, when it times out, and when the run itself
  gets HUP, INT or TERM, so a hung mutant leaves nothing running.
- **Red baseline:** if the suites fail under tracing, or a selected test fails with no
  mutant, the run stops with exit 1.
- **Invalid mutants:** a mutant that fails `bash -n` (`zsh -n` for a `.zsh` file) is
  left out of the score. A measured file that does not parse unmutated stops the run, so
  it can never read as 0 of 0.
- **Tests that did not run:** a measured file with executable lines but no covered line
  stops the run with exit 1. That happens, for example, when a suite skips because a tool
  is missing. Without this stop the file would read as 0 of 0.

**Results.** Score = killed ÷ (killed + survived), per file and total. Each survivor is
printed as `survived  file:line  operator  original  ->  mutated`, and
`.coverage/mutants.tsv` holds every result.

**Equivalent mutants.** `test/mutants-ignore.tsv` lists mutants that cannot change
behaviour: file, operator, original line text (trimmed), and a required reason,
separated by tabs. Entries match by line text, not line number, so they survive edits
elsewhere in the file. Ignored mutants are left out of the score, and a row without a
reason stops the run. Under the testing rules, each survivor gets either a test that
kills it or an ignore entry that justifies it.

**Pre-PR use.** Agents run `test/mutate.sh --changed` on the measured files they
changed, and answer every survivor with a test or an ignore entry. It does not gate on
a score yet.

**Weekly CI.** `.github/workflows/mutation.yml` runs on Mondays at 05:17 UTC and on
`workflow_dispatch`, with `contents: read` and `issues: write` only. It runs the full
set, and `test/mutation-issue.sh` maintains one open issue labelled `mutation`. The
issue holds the report: per-file and total scores, then the survivors in file order. It
closes the issue when nothing survives. The issue is posted by `github-actions`. Two
layers keep a broken run from closing the issue:

- The run step uses `shell: bash`, whose `pipefail` fails the step when `mutate.sh`
  fails, so a broken run never reaches the issue step.
- `mutation-issue.sh` refuses a report whose TOTAL scored no mutants, before any `gh`
  call.

The checkout keeps no git credentials while tests and mutants run. A `concurrency`
group runs one job at a time, so an overlapping manual run cannot open a second issue.

**A floor later.** Once a few weekly runs show a stable score, a
`test/mutation-floor.tsv` reuses the coverage ratchet check and turns the score into a
blocking check. That is a separate decision for the user. The floor file uses the
coverage floor's `path<TAB>percent` format, so the same ratchet check applies.

### Tests for the tools

The tool tests run on fixture scripts and fixture tests in a temporary directory.
`test/unit/test_coverage_tools.sh` covers the tracer, the heuristic and the ratchet.
`test/unit/test_mutate_tools.sh` covers the mutator. `test/unit/test_mutation_issue.sh`
covers the rolling issue against a fake `gh`.

- **Tracer:** a fixture with an `if`/`else`, whose test takes one branch, reports
  exactly the lines that branch executed.
- **Heuristic:** `fi`, `done`, comments, heredoc bodies and `# coverage: ignore` lines
  are excluded.
- **Ratchet:** a lowered floor fails, a missing floor fails, and `--update` raises a
  floor but never lowers one.
- **Mutator:**
  - A fixture with killable and surviving mutants reports each correctly.
  - An ignore entry removes a survivor from the score, and an entry without a reason is
    refused.
  - A mutant that hangs counts as killed by timeout. Neither a hung test nor a test that
    leaves a background process leaves anything running, even when the run itself is
    killed.
  - Mutants that do not parse, in bash and in zsh, are invalid.
  - An unparsable measured file, a file whose tests did not run, a red suite and an
    unmeasured file stop the run.
  - A mutated line keeps its backslashes.
  - `--changed` picks only the changed files.
  - One worker and many workers give the same results.
- **Rolling issue:** it creates, edits or closes the one `mutation` issue as the report
  needs. An unreadable report, a report that scored nothing and a failing `gh` call each
  fail the step, and a report that scored nothing makes no `gh` call.

### Failure modes

All of them fail closed:

- **Tracing stops working** (for example, `BASH_ENV` is no longer read): measured files
  report 0%, fall below their floors, and CI fails.
- **A new measured file:** CI fails with "no floor for FILE" until `--update` records
  one.
- **Red suite:** the mutator refuses to score.
- **A tool error in the mutator:** a measured file that does not parse, a measured file
  whose tests did not run, or a failing `coverage.sh --files` or `--lines`. The run stops
  with exit 1 instead of printing a clean-looking score.
- **A failed weekly run:** the workflow fails before the issue step, and the rolling
  issue stays as it was. A report that scored nothing is refused at the issue step too.

## Rollout

Three PRs after this spec, tracked in #142:

1. **Coverage (#144):** the zsh tracing spike, tracer, heuristic, `test/coverage.sh`,
   tool tests, an initial `test/coverage-floor.tsv` from a real run, and the CI step with
   the ratchet check. It creates `docs/design/coverage-and-mutation.md`, which the
   tools' comments cite, and adds **Coverage** to `CLAUDE.md`'s Commands.
2. **Mutation (#166):** `test/mutate.sh`, `test/mutants-ignore.tsv`, `--changed`, tool
   tests, and `.github/workflows/mutation.yml` with the rolling issue. The first full
   run's scores and survivors go in the PR description. It extends the design doc and
   adds **Mutation** to `CLAUDE.md`.
3. **Survivor triage (#178):** the first weekly run's 18 survivors (#174) each get a
   test that kills them or an ignore row with its reason.

This spec first planned four PRs. The zsh spike landed inside coverage, the weekly
workflow landed with mutation, and the survivor triage was added after the first run.

**Implementation:**

- The qa-engineer persona builds the tools and their tests.
- The release-engineer persona adds the CI step and the weekly workflow, after
  qa-engineer, since they share files.
- The orchestrating session reviews each change and re-runs every check before
  reporting it done.

## Out of scope

- A mutation floor, until weekly runs have settled.
- Coverage or mutation for the Nix modules and the nvim subtree. The subtree is its own
  repo.
- Coverage or mutation for the guardrails plugin, which moved to its own repo in #151.
- Line-exact coverage. The heuristic aims for consistency.
- Changes to the guardrails pre-PR check beyond what its documented commands pick up.
