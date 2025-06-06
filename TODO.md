# General
- [] CLI Only install option
- [] Define Optional Package lists
  - [] Desktop Environment tweaks
  - [] Streaming
  - [] Gaming
  - [] Development
  - [] 3D Modelling
  - [] Video Production
  - [] System Configuration

# Packages
-[-] Install packages

## General
- [x] `firefox`
- [x] `bitwarden`
- [x] `bw`
- [x] `discord`
- [x] `lotion`
- [x] `spotify`
- [-] `rofi` / PowerToys Run alternative
  - Configure this
  - [] window hopping, running commands, and ssh'ing from one window
  - [] Customise the theme
- [-] `ddccontrol`
  - Configure this to keep monitors at:
    - 100% during the day
    - 80% during the evening
    - 0% during the night
- [] `sxwm` / Tiling Window Manager
  - Investigate this
- [] `fprintd`
  - [] `Verify result: verify-no-match (done)` - After successfully enrolling?
- [-] `stow`
  - Run this at the end of the install script
    - `stow . --adopt`
- [-] `nvtop`
  - Deprecate this and use the [`btop` GPU config](https://github.com/aristocratos/btop?tab=readme-ov-file#gpu-compatibility)
- [] `btop`
- [-] `fastfetch`
- [-] `zsh`
  - [] Alias `Ctrl+Backspace` to `Ctrl+w`
  - [] Word navigation with `Ctrl+Arrow Keys`
- [] `xfce` / Desktop Environment
  - Investigate if this is even my Desktop Environment of choice

## Streaming

## Gaming

## Launchers
- [x] `steam`

## Development
- [-] `git`
  - [] Generate GPG signature for verified commits
- [-] `vim`/`neovim`
  - Configure this
    - [] Syntax highlighting
- [] `code`
  - Configure this
- [] `tailscale`
- [] `st`
  - [] Configure default font to `BlexMono Nerd Font Mono Regular`
  - [] Mouse Scrolling
  - [] Right click to copy selection
  - [] Hostname ASCII Art
- [] `tmux`
- [] `sipcalc`
- [-] `oh-my-posh`
  - [] Extend theme
    - [] [Python](https://ohmyposh.dev/docs/segments/languages/python)
    - [] [Kube](https://ohmyposh.dev/docs/segments/cli/kubectl)
    - [] [Helm](https://ohmyposh.dev/docs/segments/cli/helm)
    - [] [Terraform](https://ohmyposh.dev/docs/segments/cli/terraform)
    - [] [ArgoCD](https://ohmyposh.dev/docs/segments/cli/argocd)
    - [] [Docker](https://ohmyposh.dev/docs/segments/cli/docker)
    - [] [AWS](https://ohmyposh.dev/docs/segments/cloud/aws)
    - [] [Root](https://ohmyposh.dev/docs/segments/system/root)

## 3D Modelling
- [] `blender`

## Video Production
- [] `obs`
- [] Da Vinci Resolve

# System Configuration
- [] Reduce/Remove timeout from `/boot/grub/grub.cfg`
- [] Disable swap
- [] Workspace switching keybinds
- [-] Validate microphones work
  - Inputs are combined
- [] Validate camera works
- [] Unmounting cifs drives, slow on shutdown with `sudo shutdown now`, improve this