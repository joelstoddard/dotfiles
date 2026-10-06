# Coverage of the repo's shell code

Most of the repo's logic is shell: the `claude-tmux-state` hook script and autoenv (zsh).
The guardrails plugins live in
[joelstoddard/guardrails](https://github.com/joelstoddard/guardrails). Without a
measurement, an agent can add a branch to a hook with no test for it and every check
stays green.
`test/coverage.sh` measures line coverage and fails when it falls.

The first half of this document covers coverage. [Mutation](#mutation) starts after
the coverage failure modes.

## Why the tools are in the repo

- `kcov` is Linux-only in nixpkgs and cannot trace zsh.
- `bashcov` is not packaged.

A small tracer in plain bash and zsh runs on macOS and CI alike, so an agent can check
before opening a PR.

## What is measured

- `home/files/**/*.sh` and `home/files/**/*.zsh`

Trace lines from any other file, including the tests, are ignored.

The suites that run are `test/unit/test_*.sh`, each with zsh as `test/unit/run.sh`
does. Each test file runs on its own with its own trace log. `test/unit/test_rules.py`
checks documents, not shell, so it is not run.

## Tracing

Neither tracer changes a test or a script. Both write `file:line` to a log named by
`COV_LOG`, never to stdout or stderr, so tests that check output are not affected.

- **bash:** `BASH_ENV` names `test/coverage/bash_env.sh`, which every non-interactive
  bash reads. It opens a file descriptor on the log, points `BASH_XTRACEFD` at it, sets
  `PS4` to print `file:line`, and runs `set -x`. `BASH_XTRACEFD` and the `{fd}` syntax
  need bash 4.1, so the tool refuses to run on an older bash. Stock macOS bash is 3.2,
  so run it from a Nix or Homebrew bash.
- **zsh:** zsh has no `BASH_XTRACEFD`, and its xtrace goes to stderr. `ZDOTDIR` names
  `test/coverage/zdotdir`, whose `.zshenv` installs a `TRAPDEBUG` that writes
  `funcfiletrace` to the log. This measures autoenv, including code inside functions.

## Executable lines

`test/coverage/executable.awk` decides which lines count. Every line counts except:

- blank lines and comment lines;
- lines that begin with `then`, `else`, `fi`, `do`, `done`, `esac`, `in`, `;;`, `;&`,
  `;;&`, `{`, `}` or `)`, followed by nothing or by a space, `;`, `|`, `&`, `<` or `>`.
  The whole line is skipped, so `then cmd`, `else cmd` and `{ cmd; }` do not count;
- function headers, and case labels on their own or with an empty arm (`pattern) ;;`);
- continuation lines of multi-line strings, heredoc bodies and backslash continuations;
- lines ending in `# coverage: ignore <reason>`. The reason is required. Use the marker
  only for lines that cannot run.

The rules are a heuristic. They need to be consistent, not exact: floors start at
measured values, so each run compares like with like. A line miscounted the same way
every time changes no result.

A traced hit on a continuation line of a counted command is credited to the command's
counted line. `executable.awk -v spans=1` prints each such continuation line with its
counted line, and `hits()` rewrites `hits.tsv` with it, so `mutate.sh` sees the counted
line too. bash credits a multi-line command to a later line, and the line differs
between bash versions.

Known limit: a test that copies a file before sourcing it is traced under the copy's
path and not credited to the original. A byte compare cannot repair this, because the
test deletes the copy before coverage reads the traces. Tests point
`AUTOENV_HANDLER_DIR` at their own handler directory and source the real `autoenv.zsh`.

Known blind spot: code in another language inside a shell string is not measured. The
awk in `shell-split.sh` and the jq in `claude-tmux-state.sh` count as one shell line
each, and a test that runs that line covers all of it.

## Floors and the ratchet

`test/coverage-floor.tsv` holds one `path<TAB>percent` line per measured file, and a
`TOTAL` line. Percentages are rounded down to one decimal place. A value must match
`digits.digit`, and a path may appear once.

- `bash test/coverage.sh` exits 1 if a measured file or the total is below its floor,
  has no floor, or has a malformed or duplicated floor (status `BAD`).
- `bash test/coverage.sh --update` sets each floor to its current value and never lowers
  one. A new measured file gets its floor here.
- `bash test/coverage.sh --ratchet BASE` compares the floor file with a `BASE` copy,
  for example the one on `main`. It fails if any floor is lower, if a floor is
  missing while its file still exists, or if a floor on either side is malformed or
  duplicated (`floor invalid`). `TOTAL` must always exist. A floor for a deleted
  file may go. This makes "floors only rise" a machine check and not a habit.

Exit codes: 0 for success; 1 for a failed test, a missing, low or invalid floor, a
missing argument after `--lines` or `--ratchet`, or an unreadable base file; 2 for an
unknown option or a bash older than 4.1.

## Failure modes

Every one fails the run, or reads as lower coverage, never as higher, so a broken
tracer or a damaged floor file cannot hide a gap.

- **Tracing stops working** (for example, `BASH_ENV` is no longer read): measured files
  report 0% and fall below their floors.
- **A new measured file:** the run fails with `NO FLOOR` until `--update` records one.
- **A suite fails:** the run stops with exit 1 and names the log.
- **A bash older than 4.1:** the tool refuses to run. A test that starts such a bash
  inside the suite runs it untraced, and its lines show as uncovered.
- **`zsh -f`:** a zsh started with `-f` skips `.zshenv`, so it runs untraced.
- **A relative path after `cd`:** traced paths resolve from the tool's working
  directory. A suite that changes directory and then runs a script by a relative path
  loses those hits. Run such scripts by an absolute path.

## Mutation

Coverage shows that a test ran a line, not that it checks the line. `test/mutate.sh`
changes one covered line at a time and runs the tests that cover it. A mutant that
leaves every test green survived, and the line is not checked. No maintained mutation
tool exists for shell, so the mutator is plain bash, POSIX awk and perl.

`test/coverage/mutants.awk` makes the mutants. It works on the executable lines that
`coverage.sh --lines` reports and `hits.tsv` shows as covered. An uncovered line gets
no mutants, because coverage already reports it.

| Operator    | Mutation                                                                     |
| ----------- | ---------------------------------------------------------------------------- |
| Comparison  | `==` and `!=` swap; `-eq`/`-ne`, `-lt`/`-ge`, `-gt`/`-le`, `-z`/`-n` swap    |
| Logic       | `&&` and `\|\|` swap; a leading `! ` is dropped                              |
| Exit status | `exit` or `return` `0` becomes `1`; `1` becomes `0`; `exit 2` becomes `0`    |
| Boolean     | `true` and `false` swap, as whole words                                      |
| Deletion    | a simple command or assignment becomes `:`                                   |

Each restriction keeps a mutant a real fault and not noise:

- **Test operators only inside `[[`, `[` or `test`.** `-n` and `-z` are also options of
  `head`, `sort` and others. Swapping them breaks a command and not a decision.
- **Deletion only of simple commands and assignments.** Deleting `if`, `then`, `do`,
  a line that opens a block, a pipeline or a heredoc, or a continued line gives a script
  that does not parse. Such a mutant is invalid and tells nothing. Declarations with
  `local`, `declare`, `export` or `readonly` are not deleted either.
- **No mutants inside strings or comments.** A changed string is data, and the tests
  that compare it fail for a reason that is not a logic fault. A comment is not code.
  The scanner tracks quotes and backslashes so a `==` in a string is not touched.

### Running the mutants

- **Test selection.** `hits.tsv` maps each test to the lines it ran. A mutant runs only
  the tests that ran its line, and stops at the first one that fails.
- **Isolation.** The run makes one scratch copy of the working tree for each worker, so
  a mutant never touches the checkout. Each worker puts the original file back after
  each mutant. Workers take plan lines by index modulo `-j`, so one worker and many
  workers give the same results.
- **Process groups.** A test runs in its own process group, and the wrapper (perl) kills
  the group after the test exits, after a timeout, and when the run itself gets HUP, INT
  or TERM. A mutant that hangs, or a test that leaves a background process, leaves
  nothing running. Closing the pane in the middle of a run is safe for the same reason.
- **Interrupted run.** A worker ignores INT, so the main shell stops the workers itself.
  When it exits, for any reason, it sends TERM to each worker and to the wrapper of its
  test, then removes the scratch copies. It does not signal its process group, because
  the caller may share that group.
- **Timeout.** Ten times the clean run of that test, with a floor of 2s. A timeout
  exits 124 and counts as killed: a mutant that makes a test hang is detected. Exit 127
  or 255 means the wrapper failed to start the test or to fork. That is not a kill: it
  stops the run with exit 1.
- **Red baseline.** `bash test/coverage.sh --trace` runs first, and each selected test
  runs once unmutated. If one fails, the run stops with exit 1.

### Invalid mutants and errors that look like a score

A mutant that fails `bash -n` (or `zsh -n` for a `.zsh` file) is invalid. It is out of
the score, and it is neither killed nor survived. The operators should rarely make one,
but a test fixture shows the check works.

A tool error must never read as a clean score, so these stop the run:

- a measured file that does not parse unmutated (exit 1), because every mutant of it
  would be invalid and the file would score 0 of 0;
- a failing `coverage.sh --files` or `coverage.sh --lines` (exit 1), because an empty
  list reads as nothing to mutate;
- a measured file with executable lines and no covered line (exit 1), because its tests
  did not run, for example a suite that skips when a tool is missing. A file with no
  executable lines is skipped without a message;
- a failing suite (exit 1) and a failed worker (exit 1), which includes a test wrapper
  that fails by itself (exit 127 or 255).

A floor breach exits 1 (see [Floors](#floors)). Usage errors exit 2: an ignore row
without a reason, a `FILE` argument that is not measured, and `--update` with other
arguments. An ignore row that names an unmeasured file is not refused. It matches
nothing. A run with survivors and no floor breach exits 0.

### Results, equivalent mutants and the ignore file

Score is killed divided by killed plus survived, for each file and in total. The table
and the survivors, as `survived file:line operator original -> mutated`, print to
stdout. `.coverage/mutants.tsv` holds every result.

`test/mutants-ignore.tsv` lists mutants that cannot change behaviour: file, operator,
original line trimmed, and a required reason, separated by tabs. A row matches on the
line text and not the line number, so it survives edits elsewhere in the file. An
ignored mutant is out of the score. A row without a reason stops the run, so no one can
silence a survivor without saying why.

Each survivor gets a test that kills it, or a reasoned ignore row. The usual equivalent
mutant is `exit 0` to `exit 1` under `trap 'exit 0' EXIT`: the trap decides the status.

### Use

- `bash test/mutate.sh --changed` mutates the measured files that differ from
  `origin/main` or are untracked, and fails below a file's floor. Run it before a PR
  that changes measured shell.
- `bash test/mutate.sh --update` runs every file and raises the floors.
- `bash test/mutate.sh FILE...` mutates the named measured files.
- `-j N` sets the number of workers. The default is the number of CPUs. One scratch
  copy of the tree exists for each worker.

The full run on the first day took 4m59s with `-j 14` (82 of 98 mutants killed, 83.6%).
That is a macOS figure. The same run took 13s in an Ubuntu 24.04 container limited to
4 CPUs, as on the runner.

### Floors

`test/mutation-floor.tsv` has the format of `test/coverage-floor.tsv`: one
`path<TAB>percent` line per measured file and a `TOTAL` line, rounded down to one
decimal place.

- Every row of the table shows the file's floor and a status: `ok`, `LOW`, `NO FLOOR`
  or `BAD` (a floor that is not `digits.digit`, or a path with two floors). A floor
  never reads as no limit.
- The run exits 1 when any reported row is not `ok`. The table and the survivors print
  first. A run with survivors and no floor breach exits 0.
- A full run also checks `TOTAL`. A run of `FILE...` or `--changed` checks only the
  files it mutated and prints no `TOTAL`, because a partial run has no meaningful total.
- `bash test/mutate.sh --update` runs every file, then sets each floor to its current
  score and never lowers one. A new measured file gets its floor here. Combined with
  `--changed` or `FILE` it exits 2. A run that stops with an error writes nothing, and
  neither does a malformed floor.
- `bash test/coverage.sh --ratchet BASE test/mutation-floor.tsv` makes "floors only
  rise" a machine check here too, with the rules in [Floors and the ratchet](#floors-and-the-ratchet).

The floors start at 100.0 for every file.

On a pull request the `unit` job in `.github/workflows/test.yml` runs both checks after
the coverage ones: `bash test/mutate.sh` for the floors, then the ratchet against the
copy on `main`. A full run takes about 13 seconds on four CPUs, and the tool takes its
worker count from the CPU count. It needs zsh, perl and `pkill`; the job installs zsh,
and `ubuntu-latest` has the others.

The ratchet step skips with a notice when `main` has no `test/mutation-floor.tsv`, so
the pull request that adds the file can pass. The test is whether the file exists in
`main`'s tree, not whether `git show` succeeded, so a failed fetch or read still fails
the step. Once the file is on `main`, the ratchet always runs, and #186 removes the skip.

### Weekly run and the rolling issue

A weekly workflow, `.github/workflows/mutation.yml`, runs the full set and keeps one
open GitHub issue labelled `mutation` through `test/mutation-issue.sh`. The issue lists
the survivors by file with the per-file and total scores, and the workflow closes it
when nothing survives. One rolling issue replaces one issue for each survivor, which
would flood the tracker with mostly equivalent mutants.

The script refuses a report whose total scored no mutants, so a broken run never closes
the issue as if everything were killed. Only the table row counts: a survivor line that
ends in the word TOTAL does not. The report sits in a fence of four tildes, so a
survivor line with backticks cannot close it. The script takes over only an open
`mutation` issue made by `app/github-actions`, so it never edits an issue that a person
made. The job keeps no git credentials while tests
run, and runs one at a time, so an overlapping manual run cannot open a second issue.

The issue step runs with `if: ${{ !cancelled() }}`, so a floor breach, which makes
`mutate.sh` exit 1, still updates the issue, and the job ends red. This is safe because
`mutate.sh` prints the table only at the end, in `report`, after every error that stops
it (a red suite, a failed worker, a bad argument). A report from such a stop has no
scored `TOTAL` row, and `mutation-issue.sh` refuses it before any `gh` call. The run
step uses `bash` with `pipefail`, so `tee` does not hide the exit status.

### Known limits

- **Uncovered lines get no mutants.** A mutation score says nothing about them. Read it
  with the coverage report.
- **Tests that write into the tree.** A test that writes inside its scratch copy keeps
  that state for the next mutant of the same worker. No suite does so today. Every
  suite under `test/unit/` writes only to `mktemp` directories, and a full run leaves
  `git status --porcelain` showing only the files the change made (`.coverage/` is
  ignored). Check this again when a suite is added.
- **Equivalent mutants.** Some survivors cannot be killed, as above. The first run has
  several candidates, for example `exit 0` to `exit 1` after a guard under an `EXIT`
  trap, and the deletion of `set -euo pipefail`. Judge each one before an ignore row.
- **CI and macOS differ line by line.** A platform conditional is covered, and so
  mutated, on one branch only. `claude-tmux-state.sh`'s `uname == Darwin` branch runs
  locally, and the Linux branch runs in CI.
- **bash 5.2 and 5.3 trace a multi-line command differently.** The trace credits it to a
  later line, and the line differs between versions. Coverage maps such a hit to the
  counted first line, so the difference does not change the result.
- **Flaky tests.** A test that fails at random reads as a kill. The run does not retry.
- **Shell inside a string.** The awk and jq code in strings gets no mutants, as for
  coverage.
- **The scanner reads one line at a time.** It treats a `-n` or `-z` as a test operator
  when `[[`, `[ ` or `test ` comes earlier on the line, even outside the brackets. It
  does not track quotes nested inside `$( )`. Such a mutant breaks a command and is
  killed at once, or changes a string. No measured line gets such a mutant today.
