# General
- [ ] Multi OS Configuration
  - [ ] Test this out from scratch on
    - [ ] Debian
    - [ ] Ubuntu
    - [ ] MacOS
    - [ ] Arch
- [ ] Default to CLI Only install
- [ ] Centrally define colour theme/palette
  - [ ] Source colours from this central location.
    - [ ] `oh-my-posh`
    - [ ] `nvim`
    - [ ] `git`
    - [ ] `alacritty`
    - [ ] etc.
- [ ] Define Optional Package lists
- [ ] Centralise packages list so all OS installation scripts can reference the same list
  something like:
  ```python
  packages = [
    "curl",
    "wget", 
    "zsh",
  ]

  if OS = "arch":
    package_manager = "pacman"
    install_options = "-S"
  
  for package in packages:
    run(f"{package_manager} install {install_options} {package}")
  ```
- [x] Define Optional Package lists
  - [ ] Desktop
    - Firefox, notion, bitwarden, etc.
  - [ ] Streaming
    - obs, davinci resolve, etc.
  - [ ] Gaming
    - steam, discord, etc.
  - [ ] Development
    - alacritty, nvim, python, golang, etc. 
  - [ ] 3D Modelling
    - Blender.
  - [ ] System Configuration
    - This stuff like reducing the grub timeout on systems that use it so there's not a 5 second wait on boot to get to the login prompt.
- [ ] Test installation on all platforms
  - [ ] Arch Linux
  - [ ] Debian/Ubuntu
  - [ ] macOS

# Packages
- [ ] Define centralised package configuration file
    - Mutli-OS support
        - Change package name based on what OS we're installing on
    - Package groups
        - Desktop
        - Streaming & Video Production
        - Gaming
        - Development
        - 3D Modelling
        - System Configuration
- [-] Install packages

## General
- [x] `firefox`
- [x] `bitwarden`
- [x] `bitwarden-cli`
- [x] `notion`
- [x] `spotify`
- [-] `rofi`/ Find alternative for Omarchy & MacOS. 
  - Configure this
    - [x] window hopping, running commands, and ssh'ing from one window
    - [x] Customise the theme
    - [ ] Maths mode, +-*/, currency & unit conversions, etc.
- [-] `ddccontrol`
  - Only needed for Omarchy/Debian/Ubuntu installs with a desktop environment.
  - Configure this to keep monitors at:
    - [ ] 100% during the day
    - [ ] 80% during the evening
    - [ ] 0% during the night
- [ ] `fprintd`
  - [ ] `Verify result: verify-no-match (done)` - After successfully enrolling?
- [x] `stow`
  - Run this at the end of the install script
    - `stow . --adopt -t ~`
- [-] `nvtop`
  - Deprecate this and use the [`btop` GPU config](https://github.com/aristocratos/btop?tab=readme-ov-file#gpu-compatibility)
- [ ] `btop`
- [x] `fastfetch`
- [x] `zsh`
  - [ ] Utilise the `chpwd` hook for loading virtual environments in languages and tools that support it
  - [x] Alias `Ctrl+Backspace` to `Ctrl+w`
  - [x] Word navigation with `Ctrl+Arrow Keys`
- [-] Desktop Environment
  - Omarchy - ships with one
  - MacOS - ships with one, needs a window manager on top though
  - Debian/Ubuntu - GNOME

## Streaming & Video Production
- [ ] `obs`
- [ ] Da Vinci Resolve

## Gaming
- [x] `steam`
- [x] `discord`

## Development
- [x] `git`
  - [x] Generate GPG signature for verified commits
- [ ] `gh`
- [-] `neovim`
  - Note: Neovim configuration is managed in ~/personal/nvim repository
  - See ~/personal/nvim/TODO.md for neovim-specific tasks
- [ ] `tailscale`
- [x] Alacritty
  - [x] Configure default font to `BlexMono Nerd Font Mono Regular`
  - [x] Mouse Scrolling
  - [x] Right click to copy selection
  - [ ] Hostname ASCII Art (future enhancement)
- [ ] `tmux`
  - [ ] Find a session manager I like
    - [ ] [`sessionx`](https://github.com/omerxx/tmux-sessionx)
  - [ ] Work on visual clarity when paired with `neovim`
  - [ ] Always start this
  - [ ] adjust scroll sensitivity
  - [ ] control + click for links
- [x] `sipcalc`
- [x] `ripgrep`
- [x] `grex`
- [x] `oh-my-posh`
- [ ] `net-tools`
  - [-] Extend theme
    - [ ] [SSH](https://ohmyposh.dev/docs/segments/system/session)
    - [x] [Root](https://ohmyposh.dev/docs/segments/system/root)
      - [x] Show ❯ prefix character in red
    - [-] [AWS](https://ohmyposh.dev/docs/segments/cloud/aws)
      - [ ] Show 󰸏 when in an AWS repo/folder
      - [x] Display current Profile in tooltip when typing `aws`
      - [x] Display current Region in tooltip when typing `aws`
    - [-] [Terraform](https://ohmyposh.dev/docs/segments/cli/terraform)
      - [ ] Show 󱁢 when in a terraform repo/folder
      - [x] Display WorkspaceName in tooltip when typing `terraform`
    - [-] [Kube](https://ohmyposh.dev/docs/segments/cli/kubectl)
      - [ ] Show 󱃾 when in a kubernetes repo/folder
      - [ ] Display current cluster
      - [x] Display current context
    - [ ] [Helm](https://ohmyposh.dev/docs/segments/cli/helm)
      - [ ] Show  when in a helm repo/folder
    - [ ] [ArgoCD](https://ohmyposh.dev/docs/segments/cli/argocd)
      - [ ] Show  when in a ArgoCD repo/folder
    - [-] [Docker](https://ohmyposh.dev/docs/segments/cli/docker)
      - [ ] Show  when in a docker repo/folder
      - [x] Display current Context in tooltip when typing `docker`
    - [x] [Python](https://ohmyposh.dev/docs/segments/languages/python)
      - [x] Show  when a `.venv` is active in yellow ( #ffde57). 
      - [-] When currently active `.venv` is from the pwd, then change the folder colour to yellow.
    - [x] [Git](https://ohmyposh.dev/docs/segments/scm/git)
      - [x] Show current working branch
      - [x] Show icons if `.Ahead` or `.Behind`
      - [x] Show working changes
    - [x] [Secondary Prompt](https://ohmyposh.dev/docs/configuration/secondary-prompt)
      - [x] Show ❯ when in secondary prompt
    - [ ] Tailscale
      - [ ] Show connection
    - [ ] Claude
      - [ ] Show current model
      - [ ] Show current context window
      - [ ] Create custom statusline in claude code prompt

## Work
- [ ] `jfrog`
- [ ] `assume`

## 3D Modelling
- [ ] `blender`

# System Configuration
- [ ] Reduce/Remove timeout from `/boot/grub/grub.cfg`
- [ ] Disable swap
- [ ] Workspace switching keybinds
- [-] Validate microphones work
  - Inputs are combined
- [ ] Validate camera works
- [ ] Unmounting cifs drives, slow on shutdown with `sudo shutdown now`, improve this
