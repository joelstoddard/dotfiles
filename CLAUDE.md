# Dotfiles Architecture Documentation

## Overview

This dotfiles repository provides a unified configuration management system using GNU Stow for multiple operating systems: Arch Linux, Debian/Ubuntu, and macOS.

## Supported Platforms

| Platform | Status | Package Manager | Notes |
|----------|--------|-----------------|-------|
| Arch Linux | ✓ Full Support | pacman + yay | Includes Omarchy integration |
| Debian/Ubuntu | ✓ Full Support | apt | Builds some packages from source |
| macOS | ✓ Full Support | Homebrew | macOS 12.0+ recommended |
| Windows | ✗ Not Supported | N/A | See rationale below |

### Why Windows Is Not Supported

Windows is fundamentally incompatible with this dotfiles architecture:

1. **GNU Stow Incompatibility**: Stow relies on POSIX symlinks which work differently on Windows (require admin rights, NTFS symlinks vs Unix symlinks)
2. **Shell Scripts**: Installation scripts use bash and POSIX utilities not available in standard Windows
3. **Path Differences**: Windows uses backslashes, different home directory structure, and different config locations
4. **Tool Availability**: Many CLI tools (tmux, rofi, etc.) are Linux/Unix-specific

**Recommended Windows Alternatives:**
- chezmoi (https://www.chezmoi.io/) - Cross-platform dotfiles manager
- PowerShell-based dotfiles with New-Item -ItemType SymbolicLink
- yadm (https://yadm.io/) - Yet Another Dotfiles Manager
- Windows Subsystem for Linux (WSL2) with these dotfiles in the Linux environment

## Architecture

### Installation Flow

```
./install.sh
    ↓
os-detect.sh (exports OS, DISTRO, PKG_MANAGER, HAS_GUI)
    ↓
Route to OS-specific script:
    • scripts/arch.sh
    • scripts/debian-ubuntu.sh
    • scripts/macos.sh
    ↓
Common post-install:
    • Remove conflicting configs (Omarchy on Arch)
    • Conditional stow (skip rofi on non-Linux/non-GUI)
    • Stow all configs to $HOME
```

### Directory Structure

```
dotfiles/
├── .config/
│   ├── alacritty/      → Terminal emulator (cross-platform)
│   ├── git/            → Git configuration (cross-platform)
│   ├── nvim/           → Neovim (external subtree, read-only)
│   ├── oh-my-posh/     → Shell prompt theme (cross-platform)
│   ├── rofi/           → Application launcher (Linux-only)
│   └── tmux/           → Terminal multiplexer (cross-platform)
├── .zshrc              → Shell configuration
├── install.sh          → Main installation entry point
├── os-detect.sh        → OS/distro detection
├── scripts/
│   ├── arch.sh         → Arch Linux package installation
│   ├── debian-ubuntu.sh → Debian/Ubuntu package installation
│   └── macos.sh        → macOS package installation
└── TODO.md             → Task tracking

Files excluded from stowing (see .stow-local-ignore):
- README, LICENSE, TODO, CLAUDE.md
- install.sh, os-detect.sh
- scripts/
- Git metadata
```

## Configuration Management Strategy

### Cross-Platform Configs

Most configurations are naturally cross-platform:
- **tmux**: Plugins handle clipboard differences automatically
- **git**: Uses portable paths and POSIX tools
- **oh-my-posh**: Theme engine is cross-platform by design
- **nvim**: Lua-based configuration works everywhere

### Platform-Specific Handling

#### Approach 1: Comments in Config Files (alacritty)
- Keep single config file
- Add comments explaining OS-specific values
- Users manually adjust on first install
- Temporary solution until this can be templated

**Example (.config/alacritty/alacritty.toml):**
```toml
# macOS: 20 (retina displays)
# Linux: 9-12 (standard displays)
size = 20
```

#### Approach 2: Runtime Detection (.zshrc)
- Shell script detects OS at runtime
- Conditionally sets paths and loads tools

**Example (.zshrc):**
```bash
if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS-specific configuration
fi
```

#### Approach 3: Conditional Stowing (rofi)
- Some tools only work on specific platforms
- Installation script skips stowing based on OS and HAS_GUI

**Example (install.sh):**
```bash
if [[ "$OS" != "linux" || "$HAS_GUI" != "yes" ]]; then
    # Skip rofi on macOS or headless Linux
fi
```

## OS-Specific Tool Mappings

| Tool Category | Linux | macOS | Notes |
|---------------|-------|-------|-------|
| Terminal | Alacritty | Alacritty | Universal |
| Shell | zsh | zsh | Universal |
| Multiplexer | tmux | tmux | Universal |
| Editor | Neovim | Neovim | Universal |
| Launcher | rofi | Spotlight/Raycast | rofi is X11-only |
| Package Mgr | pacman/apt | Homebrew | OS-specific |
| Fonts | pacman/apt | Homebrew Cask | Different packages |

## Critical Bug Fixes (Feb 2026)

### Bug #1: Homebrew Detection (.zshrc line 5)
**Problem**: `[[ -z "/opt/homebrew/bin/brew" ]]` checks if string is empty (always false)
**Fix**: `[[ ! -f "/opt/homebrew/bin/brew" ]]` checks if file doesn't exist
**Impact**: Homebrew setup never ran on macOS

### Bug #2: Docker Completions (.zshrc line 62)
**Problem**: Hardcoded path `/Users/joel/.docker/completions`
**Fix**: Use `${HOME}/.docker/completions` and check existence
**Impact**: Broke Docker completions on Linux

### Bug #3: Alacritty Omarchy Import
**Problem**: Imports `~/.config/omarchy/current/theme/alacritty.toml` which doesn't exist on macOS/Debian
**Fix**: Comment out with note that it's Arch/Omarchy-specific
**Impact**: Silent failure, inconsistent theming

### Bug #4: PostgreSQL Path (.zshrc line 133)
**Problem**: Always adds `/opt/homebrew/opt/libpq@16/bin` to PATH
**Fix**: Only add on macOS when directory exists
**Impact**: PATH pollution on Linux

### Bug #5: Rofi Configuration
**Problem**: Multiple issues (hardcoded paths, missing import, stowed on macOS)
**Fix**: Fix paths, remove broken import, conditional stowing
**Impact**: Config errors on macOS where rofi can't run

## Configuration Details

### Alacritty (Terminal Emulator)
- **Font**: BlexMono Nerd Font Mono
  - Size: 20 on macOS (retina), 9-12 on Linux
- **Decorations**: Full on macOS, None on Linux (WM-managed)
- **Omarchy Integration**: Imports theme on Arch Linux (Omarchy systems)
- **Keybindings**: Shift+Return for Claude Code integration

### Git
- **User**: Joel Stoddard-Turvey
- **GPG Signing**: Enabled by default (key: 83C041427307B6AB)
- **Diff Tool**: nvimdiff (falls back to vim)
- **Default Branch**: main
- **Commit Template**: Conventional commits format

### Oh My Posh
- **Segments**: Python venv, path, git status, root indicator
- **Tooltips**: kubectl, terraform, AWS, Docker context
- **Auto-update**: Weekly from CDN
- **Cross-platform**: All segments work on all OSes

### Rofi (Linux Only)
- **What**: Application launcher, window switcher, run dialog
- **Dependency**: X11 or Wayland (Linux display servers)
- **Theme**: Gruvbox dark color scheme
- **Font**: Atkinson Hyperlegible Regular 12
- **macOS Alternative**: Spotlight, Raycast, Alfred

### Tmux
- **Base Index**: 1 (windows and panes)
- **Terminal**: screen-256color with RGB support
- **Plugins**: vim-tmux-navigator, tmux-resurrect, tmux-continuum, tmux-yank, sessionx
- **Scripts**: Menu system (fzf-based) and scratchpad popup
- **Cross-platform**: All plugins handle OS differences automatically

### Neovim
- **Source**: Imported from external git repository (subtree)
- **Edit Policy**: Do NOT edit in this repository
- **Update Method**: Git subtree pull from source repo
- **Last Import**: Commit 3c2e041 (Feb 17, 2025)

## Testing Strategy

### Manual Testing Per Platform

**Pre-installation checks:**
1. Clone fresh repository
2. Verify no previous dotfiles exist (or backup)
3. Clean shell environment

**Installation test:**
1. Run `./install.sh`
2. Verify OS detection is correct
3. Verify packages install without errors
4. Verify configs stow successfully
5. Open new terminal - shell loads without errors
6. Verify oh-my-posh displays correctly
7. Open Alacritty - launches and displays correctly
8. Test git commit - GPG signing works
9. (Linux GUI only) Test rofi launches

**Bug verification:**
1. Check brew command works (macOS)
2. Check Docker completions load (if Docker installed)
3. Check PostgreSQL psql command works (if needed)
4. Verify alacritty imports theme correctly (Arch) or uses inline config (others)

### Test Environments

- **Arch Linux**: Physical install or VM (test Omarchy integration)
- **Debian/Ubuntu**: VM or WSL2
- **macOS**: Physical macOS 12.0+ system (test both Intel and Apple Silicon if possible)

## Maintenance

### Adding a New Config

1. Add config to `.config/` or root directory
2. Update `.stow-local-ignore` if it shouldn't be stowed
3. If OS-specific:
   - Add installation to appropriate `scripts/*.sh` file
   - Add conditional stow logic to `install.sh` if needed
4. Test on all platforms or document OS-specific nature

### Updating Neovim Config

**DO NOT** edit `.config/nvim/` directly in this repository.

To update:
```bash
cd ~/personal/nvim/
# Make changes
git commit
cd ~/personal/dotfiles/
git subtree pull --prefix .config/nvim <neovim-repo-url> <branch> --squash
```

### Adding a New Platform

1. Create `scripts/newplatform.sh` with package installation
2. Update `os-detect.sh` to detect the new platform
3. Update `install.sh` routing logic
4. Test thoroughly
5. Update this documentation

## Troubleshooting

### Installation fails on macOS
- Check Xcode Command Line Tools: `xcode-select --install`
- Verify Homebrew installation: `brew doctor`
- Check disk permissions

### Shell doesn't load after installation
- Check `.zshrc` for syntax errors: `zsh -n ~/.zshrc`
- Test loading: `zsh -x` (verbose mode)
- Check oh-my-posh installed: `which oh-my-posh`

### Alacritty fails to launch
- Verify font installed: `fc-list | grep BlexMono` (Linux) or check Font Book (macOS)
- Check config syntax: alacritty will log to stderr
- Remove Omarchy import line if not on Arch

### GPG signing fails
- Check GPG key exists: `gpg --list-keys`
- Verify GPG_TTY set: `echo $GPG_TTY`
- Import key: `gpg --import /path/to/key`

### Rofi doesn't work on macOS
- This is expected - rofi is Linux-only
- Use Spotlight (Cmd+Space) or install Raycast/Alfred as alternative
- Installation script should skip stowing rofi on macOS

## Version History

- **Feb 2026**: Multi-OS support implementation, critical bug fixes, macOS script completion
- **Feb 2025**: Neovim subtree import, Omarchy branch creation
- **Earlier**: Initial repository creation

## References

- GNU Stow: https://www.gnu.org/software/stow/
- Oh My Posh: https://ohmyposh.dev/
- Alacritty: https://alacritty.org/
- Neovim: https://neovim.io/
