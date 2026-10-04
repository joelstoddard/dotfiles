# Coverage of the repo's shell code

Most of the repo's logic is shell: the guardrails plugin (`lib/` and `hooks/scripts/`),
the `claude-tmux-state` hook script, and autoenv (zsh). Without a measurement, an
agent can add a branch to a hook with no test for it and every check stays green.
`test/coverage.sh` measures line coverage and fails when it falls.

This document covers coverage only.

## Why the tools are in the repo

- `kcov` is Linux-only in nixpkgs and cannot trace zsh.
- `bashcov` is not packaged.

A small tracer in plain bash and zsh runs on macOS and CI alike, so an agent can check
before opening a PR.

## What is measured

- `home/files/**/*.sh` and `home/files/**/*.zsh`
- `.claude/marketplace/plugins/guardrails/lib/*.sh`
- `.claude/marketplace/plugins/guardrails/hooks/scripts/*.sh`

Trace lines from any other file, including the tests, are ignored.

The suites that run are `test/unit/test_*.sh`, each with zsh as `test/unit/run.sh`
does, and the guardrails `tests/test_*.sh`, each with bash as that plugin's runner does.
Each test file runs on its own with its own trace log. `test/unit/test_personas.py`
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

Known limits:

- A multi-line command counts on its first line, but bash credits a hit to a different
  line, so that first line reads as uncovered.
- A file a test copies before sourcing is traced under the copy's path and is not
  credited to the original (for example `autoenv.zsh:30-31`).

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
