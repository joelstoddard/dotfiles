# dotfiles

Unified dotfiles for Arch Linux (Omarchy), Debian/Ubuntu, and macOS.

## Design Philosophy

1. **Stay on the beaten path** — configuration should feel natural
2. **Choose boring technologies** — stable, maintenance-friendly tools
3. **Minimal plugins and aliases** — no magic, no obscured commands
4. **Minimize visual distraction** — show info only when useful

## Quick Start

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./install.sh          # CLI-only (core + dev + work packages)
./install.sh --gui    # Include desktop, gaming, streaming packages
```

## Uninstall

```bash
./uninstall.sh        # Removes symlinks only, keeps installed packages
```

## Architecture

```
install.sh (bash shim)
  └─ scripts/install.py
       ├─ Reads packages/packages.yaml
       ├─ Detects OS (macOS / Arch / Debian / Ubuntu)
       ├─ Installs packages (idempotent — skips already installed)
       ├─ Generates zsh completions + theme colors
       ├─ Applies GNU Stow (symlinks configs to $HOME)
       └─ Runs verification checks
```

## What's Configured

| Tool | Config | Notes |
|------|--------|-------|
| zsh | `.zshrc` | Manual plugin loading, no Zinit/OMZ |
| git | `.config/git/` | GPG signing, conventional commits |
| tmux | `.config/tmux/` | TPM plugins, vim-tmux-navigator |
| oh-my-posh | `.config/oh-my-posh/` | Prompt theme with git, python, k8s |
| alacritty | `.config/alacritty/` | OS-specific via symlinked `os.toml` |
| neovim | `.config/nvim/` | Git subtree (managed in separate repo) |

## Package Categories

| Category | Flag | Contents |
|----------|------|----------|
| core | always | git, zsh, tmux, nvim, fzf, ripgrep, oh-my-posh, ... |
| development | always | go, python, terraform, kubectl, docker, ... |
| work | always | jfrog, granted |
| desktop | `--gui` | firefox, alacritty, bitwarden, spotify, fonts |
| gaming | `--gui` | discord, steam |
| streaming | `--gui` | obs, davinci resolve |
| 3d-modelling | `--gui` | blender |

## Color Palette

Colors are defined in `theme/palette.yaml` and generated into tool-specific configs:

```bash
make generate-theme   # Regenerate .config/alacritty/colors.toml
```

## Testing

```bash
make test             # Docker-based tests for Debian, Ubuntu, Arch
make verify           # Post-install verification
```
