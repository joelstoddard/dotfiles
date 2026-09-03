# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# dotfiles

## Architecture

- **Nix flake + Home Manager** manage packages and configs declaratively. No stow, no installer scripts.
- `flake.nix` defines one `homeConfigurations` entry per host; behavior is driven by the `dotfiles.*` module options (`gui`, `omarchy`, `work`, `repoPath`).
- All modules live in `home/`. Verbatim config files (oh-my-posh themes, btop theme, autoenv zsh scripts) live in `home/files/` and are linked with `xdg.configFile`.

## Key Files

- `flake.nix` — inputs (nixpkgs unstable, home-manager) and host configs
- `home/default.nix` — module imports + `dotfiles.*` option declarations
- `home/palette.nix` — ash-plus colors, single source of truth (consumed by alacritty/git/tmux modules)
- `home/packages.nix` — every package for all platforms (was `packages/packages.yaml`)
- `home/pkgs/ttl.nix` — custom derivation for tools missing from nixpkgs
- `home/files/` — files kept byte-for-byte and linked, not rewritten in Nix
- `.claude/user-settings.json` — user-level Claude Code settings, linked to `~/.claude/settings.json` by `home/claude.nix`. `.claude/settings.json` is this repo's own project settings; the two are different files. See `docs/design/claude-settings-split.md`

## Patterns

- **Rewrite, don't link**: tool configs are native Home Manager options (`programs.zsh`, `programs.git`, …). Only files that must be preserved byte-for-byte (Nerd Font glyphs) or that are code (autoenv handlers) live in `home/files/`.
- **Platform differences** use `pkgs.stdenv.isDarwin` / `isLinux` conditionals, not separate files.
- **Neovim**: `.config/nvim/` is a git subtree from `~/personal/nvim` — DO NOT edit it here. It is linked out-of-store (`mkOutOfStoreSymlink`) so lazy.nvim can write `lazy-lock.json`; the link target comes from `dotfiles.repoPath`.
- **oh-my-posh theme files** (`home/files/oh-my-posh/*.yaml`): templates contain Nerd Font glyphs in the Unicode Private Use Area (e.g. `U+E0A0` branch, `U+EA7F`/`U+EB43`/`U+EA81` git status). The Read tool renders these as blank spaces — they are NOT whitespace. Never retype these files; copy with `sed`/Python and round-trip through `od -c` byte inspection.
- **btop**: Home Manager owns `btop.conf` as a read-only symlink, so `save_config_on_exit` stays false and in-app tweaks must be ported into `home/btop.nix`.

## Git Worktrees

- Use `.claude/worktrees/<branch-name>` for all git worktrees (already in `.gitignore`)
- Testing changes from a worktree is safe: `home-manager switch --flake /path/to/worktree#<host>` activates that worktree's config; switching back from the main checkout restores it.

## Platform Support

| Platform | Host config | Notes |
|----------|-------------|-------|
| macOS | `joel@macos` | Primary dev machine; GUI apps stay in Homebrew casks |
| Arch Linux | `joel@omarchy` | Omarchy integration via `dotfiles.omarchy` |
| Debian/Ubuntu | `joel@linux`, `joel@linux-desktop` | Server + desktop |

## Committing

Always use the `guardrails:commit` skill for all git commits — invoke it via the Skill tool. Applies to all agents including sub-agents.

## Commands

- **Test:** `zsh test/unit/test_autoenv.sh`

The autoenv suite is what the guardrails push gate resolves, so it stays fast
and needs no Nix. CI additionally evaluates every host with `nix flake check`.

```bash
home-manager switch --flake .#<host>       # apply configuration
nix flake check --no-build                 # evaluate all host configs
nix build --dry-run .#homeConfigurations."joel@linux".activationPackage
nix flake update                           # bump inputs
nix fmt                                    # format Nix files (nixfmt-rfc-style)
zsh test/unit/test_autoenv.sh              # autoenv shell unit tests
```
