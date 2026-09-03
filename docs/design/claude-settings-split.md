# Claude Code settings: three files, two of them tracked

## The problem

Claude Code reads settings from three places, in increasing precedence:

1. `~/.claude/settings.json` — user level, applies to every repo on the machine.
2. `<project>/.claude/settings.json` — project level, committed with the repo.
3. `<project>/.claude/settings.local.json` — project level, machine-local.

This repo links its contents into `$HOME`. That makes one repo path serve two
different roles at once: `.claude/settings.json` is this project's own settings
file *and* the obvious source for `~/.claude/settings.json`. Both are real files
with different content, and one path cannot be both, so the user-level file went
untracked and drifted — 214 lines live against a 29-line project file that was
mistaken for a stale copy.

## The constraint

This repo is public (confirmed via `gh repo view --json visibility`).

The live user-level settings carried an `autoMode.environment` block of 24 items
describing an employer environment — the GitHub org, private repo names, cloud
infrastructure references, and the locations of sensitive data. Two of the
registered plugin marketplaces also pointed at internal paths and private repos.

Committing the file whole would publish an employer's internal security posture
into public git history, where deletion does not undo the exposure. That applies
to this document too: it states the shape of the problem and names none of it.

## The design

Three files, split by audience rather than by scope:

| File | Tracked | Holds |
|---|---|---|
| `.claude/user-settings.json` | yes | user-level config safe to publish: permissions tiers, model, statusline, editor, TUI and effort preferences, public plugin and marketplace registrations |
| `.claude/settings.json` | yes | this project's own settings — dotfiles-specific git/gh permissions, `opus[1m]`, the oh-my-posh statusline |
| `.claude/settings.local.json` | no (gitignored) | employer environment context, work marketplaces and their plugins, machine-local permission grants |

`user-settings.json` carries a different name from the project file for exactly
that reason. `home/claude.nix` links `~/.claude/settings.json` to it with
`mkOutOfStoreSymlink`, not a read-only store copy, because Claude Code writes
this file in place — the same reason `home/nvim.nix` links out-of-store.

The tracked file holds no absolute paths, because it is linked on macOS, Arch
and Debian alike. Two entries needed changing for that:

- The home read grant is `Read(~/**)`, not `Read(//Users/joel/**)`.
- This repo's own plugin marketplace is no longer declared there. Claude Code
  normalises a marketplace path to absolute when it stores one — verified by
  running `claude plugin marketplace add` with a `~`-relative path and reading
  back what it wrote — so no single stored value is correct on every machine.
  Run `claude plugin marketplace add --scope local` once per machine instead: it
  writes that machine's path into `.claude/settings.local.json`. That file is
  gitignored, and `home/claude.nix` links it to `~/.claude/` as well, so the
  declaration lands in both places it is needed and in none that git tracks.
  Nothing runs this for you — it is the one manual step of a fresh setup.

Claude Code merges the user and local files, so the work context still applies at
runtime — it simply never enters git.

## Rejected alternatives

- **Link `.claude/settings.json` to `~/.claude/settings.json` directly.**
  Collides with the project settings file, as above. One of the two would have
  to lose its content.
- **Rename the project settings file instead.** Claude Code fixes that name; only
  the user-level file is free to move.
- **Commit the user file whole and make the repo private.** Solves the leak,
  costs the repo its public purpose as a reference dotfiles setup, and still
  leaves employer context in a personal repo.
- **Sanitise the work context and commit it anyway.** Every future edit would
  need the same review, and one missed edit publishes it.
- **Copy the file in and out with a make target.** No symlink to break, but drift
  returns the moment a `/permissions` change lands between syncs — the failure
  this design exists to end.

## `autoMode` never belongs in the tracked file

Claude Code generates `autoMode.environment` — a description of the current
repo's org, cloud, branch protection and sensitive-data locations — and writes it
to the **user-level** settings file. Since that path is a symlink into this repo,
each new repo worked in dirties the tracked file with another repo's context.

That is a leak path, not just churn: generate it while working in an employer
repo and employer infrastructure lands in a file staged for a public commit. It
is also pointless to track, because `settings.local.json` overrides the key
wholesale, so a tracked copy never takes effect.

So `autoMode` lives only in `settings.local.json`. The `no-automode` flake check fails if the
tracked file contains the key, because the drift is silent and a reviewer will
not notice another 25 lines of prose in a large JSON diff.

## Failure mode to watch

Claude Code rewrites user settings when `/permissions` or `/config` changes, or
when a permission prompt is answered with "always allow". An in-place write
follows the symlink and lands in the repo, which is the intent. A write that
instead creates a temporary file and renames it over the target would replace the
symlink with a regular file, and drift would resume silently.

Check with `readlink ~/.claude/settings.json` after any bulk permissions change;
`home-manager switch --flake .#<host>` restores the link.

Adding a key to the tracked file also means deciding it is publishable. Anything
naming an employer, an internal host, a private repo or a credential belongs in
`settings.local.json`.
