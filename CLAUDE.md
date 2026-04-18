# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# dotfiles

## Architecture

- **GNU Stow** manages symlinks from this repo to `$HOME`. The repo root mirrors `$HOME` structure.
- **Python installer** (`scripts/install.py`) reads `packages/packages.yaml` and installs packages directly — no code generation pipeline.
- **Flat layout**: `.config/`, `.zshrc` at repo root. Non-config dirs (`scripts/`, `packages/`, `theme/`, `test/`) excluded via `.stow-local-ignore`.

## Key Files

- `install.sh` — bash shim that bootstraps Python venv and runs `scripts/install.py`
- `scripts/lib/` — shared Python modules: `os_detect.py`, `packages.py`, `stow.py`, `github.py`
- `packages/packages.yaml` — single source of truth for all packages across all OSes
- `theme/palette.yaml` — central color definitions, generates `.config/alacritty/colors.toml`
- `.zshrc` — manual plugin loading (sources from `~/.local/share/zsh/plugins/`), NVM lazy-loaded
- `scripts/verify.py` — post-install sanity checks (symlinks, binaries, config syntax)
- `scripts/generate_completions.py` — generates zsh completions for kubectl, helm, gh, docker, etc.

## Git Worktrees

- Use `.claude/worktrees/<branch-name>` for all git worktrees (already in `.gitignore`)
- **Never re-stow from a worktree.** Do not run `stow .` or `stow . --adopt` from inside a worktree — it will overwrite the existing `$HOME` symlinks that point at `~/personal/dotfiles` and cause churn across unrelated configs.
- **Testing changes from a worktree**: create targeted `ln -s` symlinks only for the specific new/changed files under test. Point them at the worktree path. Minimal disruption, easy to revert.
- **Restoring after testing**: `cd ~/personal/dotfiles && git pull && ./install.sh --skip-packages` re-stows from the main repo and replaces any worktree-pointing symlinks back to main.

## Platform Support

| Platform | Package Manager | Notes |
|----------|----------------|-------|
| macOS | Homebrew | Primary dev machine |
| Arch Linux | pacman + yay | Omarchy integration |
| Debian/Ubuntu | apt | Server + desktop |

## Patterns

- **Idempotent installs**: every package checks `command -v` or custom `check` before installing
- **GitHub Releases API**: `github-release` type in packages.yaml fetches latest URLs at install time
- **Alacritty OS config**: `os.toml` symlink created by installer pointing to `macos.toml`, `arch.toml`, or `linux.toml`
- **Neovim**: git subtree from `~/personal/nvim` — DO NOT edit `.config/nvim/` directly
- **Stow adopt**: `stow . --adopt` is used, which pulls existing `$HOME` files into the repo before symlinking — be careful with pre-existing configs
- **oh-my-posh theme files** (`.config/oh-my-posh/*.yaml`): templates contain Nerd Font glyphs in the Unicode Private Use Area (e.g. `U+E0A0` branch, `U+EA7F`/`U+EB43`/`U+EA81` git status, `U+F0C7`, `U+EAA1`, `U+EA9A`). The Read tool renders these as blank spaces — they are NOT whitespace. When copying templates between theme files, inspect raw bytes with `od -c <file>` or `python3 -c "[print(f'U+{ord(c):04X}') for c in open(sys.argv[1]).read() if ord(c) > 127]"`, or copy via `sed`/Python rather than re-typing. Always round-trip through byte inspection to confirm icons are preserved.

## packages.yaml Reference

**Categories**: `core`, `development`, `work` (always installed); `desktop`, `gaming`, `3d-modelling`, `streaming-video-production` (with `--gui`)

**Install types** (per-OS field value):
- `~` (tilde) — native package manager (pacman/apt/brew), package name = key
- `string` — native package manager with a different package name
- `type: default` — native package manager with extra options
- `type: github-release` — downloads latest release asset (requires `repo`, `asset` glob, `install` command)
- `type: script` — runs a URL-based installer (`url` field)
- `type: cask` / `type: tap` — Homebrew cask/tap (macOS only)
- `type: yay` — AUR (Arch only)
- `type: apt-repo` — adds a custom apt repo first (`setup` script), then installs
- `type: cargo` — installs via `cargo install`

The `check` field overrides the default `command -v <key>` existence check.

## Committing

Always use the `commit` skill for all git commits — invoke it via the Skill tool. Applies to all agents including sub-agents.

## Commands

```bash
./install.sh [--gui] [--yes] [--dry-run]                  # Full install
./install.sh --include core,development --skip-stow        # Packages only, specific categories
./install.sh --skip-packages                               # Stow symlinks only
./uninstall.sh                                             # Remove symlinks (does not uninstall packages)
make generate-theme                                        # Regenerate Alacritty colors from palette.yaml
make generate-completions                                  # Regenerate zsh completions
make verify                                                # Post-install sanity checks
make test                                                  # Docker-based integration tests (Debian/Ubuntu/Arch)
```

Tests spin up Docker containers per distro, run `install.sh --yes --skip-stow --include core`, then verify — no unit tests exist.
