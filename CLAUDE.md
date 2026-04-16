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
