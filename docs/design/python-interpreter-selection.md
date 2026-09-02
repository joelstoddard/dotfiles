# Choosing a Python interpreter in `install.sh`

`install.sh` does not use `python3` directly. It walks a list of candidate
interpreters, runs a probe against each, and uses the first that passes.

## Problem

The installer needs an interpreter that can do two things: run the code in
`scripts/`, which uses `match` statements and therefore needs 3.10+, and create a
virtualenv. The obvious check is a version comparison, and it is not sufficient.

A Homebrew Python bottle can be installed, on `PATH`, and importable, while still
being unable to create a venv. The case that motivated this: a bottle whose
`pyexpat` was linked against a system `libexpat` too old for it. `python3 --version`
answers correctly, `import sys` works, and `python3 -m venv` fails — several steps
later, with an error that points at the venv rather than at the interpreter.

## The constraint

This runs before anything else in the bootstrap, on a machine that by definition
has not been provisioned yet. There is no venv to fall back into and no installed
tooling to diagnose with, so a wrong choice here surfaces as a confusing failure
much further down.

## Design

Validate rather than trust. For each candidate in
`python3.13 python3.12 python3.11 python3.10 python3.14 python3`, run a probe that
imports the modules venv creation actually needs (`ensurepip`, `pyexpat`) and
asserts `sys.version_info >= (3, 10)`. The first candidate that exits 0 wins.

The ordering is deliberate: explicit versions before the bare `python3` alias, so
a working pinned interpreter is preferred over whatever `python3` currently points
at. `python3.14` sits after `3.10` because it is newest and least likely to have
the full set of working bottles.

## What was rejected

- **Trusting `python3`.** The failure above is exactly this.
- **A version check alone.** Version is necessary but not sufficient; the broken
  bottle reports a perfectly good version.
- **Actually creating a throwaway venv as the probe.** Correct, but slow enough to
  notice when run against six candidates, and it needs a writable temp dir before
  the installer has established one.

## Failure mode if you change this

Dropping a module from the probe import list re-opens the class of bug where an
interpreter passes selection and fails at venv creation. If venv creation starts
needing another stdlib module, add it to the probe — the probe is meant to be a
proxy for `-m venv`, and it is only as good as that list.
