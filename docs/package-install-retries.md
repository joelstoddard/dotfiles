# Why AUR installs get an outer retry loop

`scripts/lib/packages.py` wraps `yay -S` in a three-attempt shell loop with a 30s
pause between attempts. Native package managers (pacman, apt, brew) get no such
wrapper.

## Problem

AUR packages are build recipes, not binaries. A PKGBUILD fetches its sources from
whatever origin the upstream author chose — a personal domain, a university
mirror, a small project's own server. Those origins are transiently unreachable
far more often than a distribution mirror is. The `sipcalc` PKGBUILD, for example,
pulls from `routemeister.net`.

The practical effect is that a full `install.sh` run fails part-way through for a
reason that has nothing to do with the machine being provisioned, and the whole
run has to be restarted.

## The constraint

`yay` already retries, but its retries are roughly 3 seconds apart. That spacing
is tuned for a mirror hiccup, not for an origin that is briefly down. Three
attempts inside ten seconds nearly always fail together, because the outage that
caused the first failure has not resolved yet.

## Design

An outer loop of 3 attempts with a 30s pause covers a ~60 second window instead of
a ~10 second one, which is enough to ride out the common case. On the third
failure the loop echoes the package name and exits 1, so the failure is
attributable rather than silent.

The loop is generated as shell rather than driven from Python because package
installs are emitted as shell commands for the caller to run.

## What was rejected

- **Raising `yay`'s own retry count.** It does not change the spacing, so the
  attempts still land inside the same outage.
- **Retrying every package manager.** Native repos are mirrored and highly
  available; a retry loop there hides real failures rather than absorbing
  transient ones.
- **A longer backoff.** 30s already covers the observed cases, and an install run
  that stalls for minutes on one package looks like a hang.

## Failure mode if you change this

Removing the loop returns to whole-run failures triggered by a third-party origin
being down for a few seconds. Extending it to native package managers means a
genuinely missing or renamed package takes three times as long to report, and the
error the user finally sees is the retry message rather than the package
manager's own diagnostic.
