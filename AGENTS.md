# AGENTS.md

A Neovim 0.12 config. Plugins install with the built-in `vim.pack`. This repo is a squashed subtree at
`.config/nvim` in joelstoddard/dotfiles: a change reaches the live editor only after a subtree pull there.

## Commands

- **Lint:**
  - `nix run nixpkgs#lua51Packages.luacheck -- init.lua lua tests`
  - `nix run nixpkgs#stylua -- --check init.lua lua tests` (format with the same command minus `--check`)
- **Test:** `sh tests/run.sh`, or `sh tests/run.sh tests/test_<area>.lua` for one file.
  - The first run installs every plugin, parser and Mason tool into `~/.local/share/nvim-test`, which takes several
    minutes. If it stops part-way (for example, a network drop), rerun it: finished items are kept.
  - The suite runs against the committed `nvim-pack-lock.json`: each run moves the test install's plugins to its
    revisions. A plugin added to `lua/plugins/init.lua`, or one with a changed `version` or source, must be pinned
    with `sh tests/run.sh --update`, which also bumps every other plugin to its latest allowed revision.
  - `sh tests/run.sh --update` updates every plugin, rewrites `nvim-pack-lock.json`, then runs the suite. It is the
    only command that changes the lockfile.
  - Do not run two suites at once when their lockfiles differ, or alongside `--update`: they share that install, and
    each run moves its plugins.
  - Each test case starts its own nvim on this checkout's config, through `tests/helpers.lua`.
  - Mason checks its registry online about once a day. Offline, that check warns, and the startup test reports the
    warning.
- **CI:** `.github/workflows/test.yml` runs both lint commands and the suite on every PR and every push to main. A
  weekly workflow opens a draft `chore(deps): update plugins` PR, already tested against the new lockfile. That
  workflow needs "Allow GitHub Actions to create and approve pull requests" turned on (Settings → Actions → General),
  or its PR step fails. The bot force-updates `chore/update-plugins` on each run, so fix `main` rather than pushing
  to that branch.

## Layout

- `init.lua`: load order.
- `lua/config/`: core settings, keymaps, autocommands, LSP, indent shading.
- `lua/plugins/`: one file per plugin; `init.lua` there lists every plugin for `vim.pack`.
- `lua/languages/`: one file per language (parsers, servers, linters, formatters, line length); a new language file
  also needs an entry in the `names` list in `lua/languages/init.lua`.
- `tests/`: the suite (mini.test), the runner and the install bootstrap.

## Conventions

- Work in a git worktree, never in the main checkout.
- Write the failing test first, with `sh tests/run.sh <file>`.
- Specs stay untracked in `.claude/specs/`: committed files are copied into the dotfiles.
- Test fixtures go in temporary folders outside the repo. yamlls skips validation for files under git-ignored
  folders, so a fixture there can pass for the wrong reason.
- Never point a test or a worktree config at `~/.local/share/nvim`.
- In the live editor, never run plain `vim.pack.update()`: it moves plugins past the lockfile and rewrites the
  dotfiles copy. After a subtree pull, run `:PackSync`.
- When removing a plugin, delete its entry from `nvim-pack-lock.json` in the same change. After the subtree pull,
  run `:lua vim.pack.del({ '<name>' })` in the live editor.
- One-off, after #19 merges: delete the untracked `~/personal/dotfiles/.config/nvim/nvim-pack-lock.json` before the
  next subtree pull (the pull refuses to overwrite it), then run `:PackSync`.
