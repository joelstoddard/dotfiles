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
- `.zshrc` — manual plugin loading (no Zinit, no OMZ), NVM lazy-loaded

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

## Commands

```bash
./install.sh [--gui] [--yes] [--dry-run]   # Install
./uninstall.sh                               # Remove symlinks
make generate-theme                          # Regenerate color configs
make verify                                  # Post-install checks
make test                                    # Docker-based OS tests
```
