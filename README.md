# dotfiles

Unified dotfiles for Arch Linux (Omarchy), Debian/Ubuntu, and macOS — as a
[Nix flake](https://nixos.wiki/wiki/Flakes) with
[Home Manager](https://github.com/nix-community/home-manager).

## Design Philosophy

1. **Stay on the beaten path** — configuration should feel natural
2. **Choose boring technologies** — stable, maintenance-friendly tools
3. **Minimal plugins and aliases** — no magic, no obscured commands
4. **Minimize visual distraction** — show info only when useful

## Quick Start

```bash
# 1. Install Nix (any distro / macOS)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone and switch
git clone <repo> ~/personal/dotfiles
cd ~/personal/dotfiles
nix run home-manager/master -- switch --flake .#joel@macos      # macOS
nix run home-manager/master -- switch --flake .#joel@omarchy    # Arch (Omarchy, GUI)
nix run home-manager/master -- switch --flake .#joel@linux      # Debian/Ubuntu server
```

After the first switch, `home-manager switch --flake .#<host>` is on PATH.

### Migrating from the stow setup

Remove the stow symlinks **before** the first switch. Home Manager backs up
regular files it would clobber (`-b`), but it never backs up a symlink, and a
surviving `~/.config/<tool>` *directory* symlink is worse: activation writes
through it into the repo working tree rather than into `$HOME`.

```bash
find ~/.config -maxdepth 2 -type l | while read -r l; do
  case "$(readlink "$l")" in *personal/dotfiles*) rm "$l";; esac
done
[ -L ~/.zshrc ] && rm ~/.zshrc

nix run home-manager/master -- switch -b hm-bak --flake .#joel@macos
```

`-b hm-bak` handles the regular files that remain (`.zprofile`, `.zshenv`).
If a switch does write into the repo, `git status` shows the config files as
type-changed with `.hm-bak` siblings; `git checkout -- .config/` restores them.

## Uninstall

```bash
home-manager uninstall   # removes generated files/links, keeps Nix itself
```

## Architecture

```
flake.nix                 # inputs (nixpkgs, home-manager) + one config per host
  └─ home/
       ├─ default.nix     # module list + dotfiles.{gui,omarchy,work,repoPath} options
       ├─ palette.nix     # ash-plus colors — single source of truth for theming
       ├─ packages.nix    # every package, all platforms (was packages/packages.yaml)
       ├─ zsh.nix         # was .zshrc (plugins + completions now come from Nix)
       ├─ git.nix         # was .config/git/
       ├─ tmux.nix        # was .config/tmux/ (TPM replaced by Nix plugins)
       ├─ oh-my-posh.nix  # theme YAMLs linked verbatim from home/files/
       ├─ alacritty.nix   # was .config/alacritty/*.toml (os.toml → Nix conditionals)
       ├─ btop.nix        # was .config/btop/
       ├─ nvim.nix        # links .config/nvim (git subtree) out-of-store
       ├─ fonts.nix       # nerd fonts (Linux GUI)
       ├─ claude.nix      # links .claude/ user config into ~/.claude/
       └─ pkgs/ttl.nix    # custom package not in nixpkgs
```

## Hosts

| Host | System | Notes |
|------|--------|-------|
| `joel@macos` | aarch64-darwin | CLI via Nix; GUI apps stay in Homebrew casks |
| `joel@omarchy` | x86_64-linux | GUI + Omarchy Alacritty theme integration |
| `joel@linux-desktop` | x86_64-linux | GUI, no Omarchy |
| `joel@linux` | x86_64-linux | Headless server, CLI only |

Host behavior is driven by module options: `dotfiles.gui`, `dotfiles.omarchy`,
`dotfiles.work`, and `dotfiles.repoPath` (where this repo is checked out,
used for the Neovim out-of-store symlink).

## What's Configured

| Tool | Module | Notes |
|------|--------|-------|
| zsh | `home/zsh.nix` | autosuggestions + completions from Nix, no plugin cloning |
| git | `home/git.nix` | GPG signing, conventional commits |
| tmux | `home/tmux.nix` | Nix-managed plugins (no TPM), vim-tmux-navigator |
| oh-my-posh | `home/oh-my-posh.nix` | prompt theme with git, python, k8s |
| alacritty | `home/alacritty.nix` | OS differences via Nix conditionals |
| btop | `home/btop.nix` | ash-plus theme |
| neovim | `home/nvim.nix` | config is a git subtree (managed in separate repo) |

## Color Palette

Colors are defined once in `home/palette.nix` (ash-plus) and consumed by the
alacritty, git, and tmux modules — no generation step anymore.

## Updating

```bash
nix flake update            # bump nixpkgs + home-manager
home-manager switch --flake .#<host>
```

## Testing

```bash
nix flake check --no-build            # evaluate all host configs
nix build --dry-run .#homeConfigurations."joel@linux".activationPackage
zsh test/unit/test_autoenv.sh         # autoenv shell unit tests
```

## Notes on the migration from stow

- GNU Stow, `install.sh`, the Python installer, `packages.yaml`, and the
  theme/completions generators are gone — Nix + Home Manager replace all of it.
- Homebrew stays on macOS for GUI casks. `brew shellenv` prepends
  `/opt/homebrew/bin`, so `home/zsh.nix` re-prepends the Nix profile after it —
  otherwise leftover Homebrew CLI formulae shadow the nixpkgs ones.
- One manual step per machine: `claude plugin marketplace add --scope local`
  (the stored path is absolute, so it cannot be tracked — see
  `docs/design/claude-settings-split.md`).
- nvm was dropped in favor of a Nix-managed Node.js; use per-project flake
  devShells or direnv for version pinning.
- On macOS, GUI apps (Firefox, Bitwarden, Spotify, Raycast, LinearMouse,
  Alacritty.app, fonts) remain Homebrew casks; nixpkgs handles all CLI tools.
- On non-NixOS Linux, Steam and DaVinci Resolve may work better from the
  distro's native packages; both are still declared for NixOS hosts.
