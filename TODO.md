# General
- [ ] Multi OS Configuration
- [ ] CLI Only install option
- [ ] Define Optional Package lists
  - [ ] Desktop Environment tweaks
  - [ ] Streaming
  - [ ] Gaming
  - [ ] Development
  - [ ] 3D Modelling
  - [ ] Video Production
  - [ ] System Configuration
- [ ] Fetch secrets from BW
  - [ ] Voyager credentials

# Packages
-[-] Install packages

## General
- [x] `firefox`
- [x] `bitwarden`
- [x] `bw`
- [x] `discord`
- [x] `lotion`
- [x] `spotify`
- [x] `rofi` / PowerToys Run alternative
  - Configure this
    - [x] window hopping, running commands, and ssh'ing from one window
    - [x] Customise the theme
- [-] `ddccontrol`
  - Configure this to keep monitors at:
    - [ ] 100% during the day
    - [ ] 80% during the evening
    - [ ] 0% during the night
- [ ] `sxwm` / Tiling Window Manager
  - Investigate this
- [ ] `fprintd`
  - [ ] `Verify result: verify-no-match (done)` - After successfully enrolling?
- [-] `stow`
  - Run this at the end of the install script
    - `stow . --adopt`
- [-] `nvtop`
  - Deprecate this and use the [`btop` GPU config](https://github.com/aristocratos/btop?tab=readme-ov-file#gpu-compatibility)
- [ ] `btop`
- [-] `fastfetch`
- [-] `zsh`
  - [ ] Alias `Ctrl+Backspace` to `Ctrl+w`
  - [ ] Word navigation with `Ctrl+Arrow Keys`
- [ ] `xfce` / Desktop Environment
  - Investigate if this is even my Desktop Environment of choice

## Streaming

## Gaming

## Launchers
- [x] `steam`

## Development
- [-] `git`
  - [ ] Generate GPG signature for verified commits
  - [ ] Clean up commands
    - [ ] `git diff`
      - [ ] Remove `meta`, `frag`, `func`, only really need to see what's changed, some context lines, and what file the changes are in.
      - [ ] Alias `git diff` to `git difftool`
    - [x] `git log`
      - [x] More compact git log
      - [x] `--graph`
        Can't just default this to on, I'll have to remember to pass the arg.
      - [x] Shorten information about commit authors
      - [x] Remove date
        This is handy every now and then, I'll keep it for now but can remove it later if I find it's just too much noise.
      - [x] Maybe `--oneline`
    - [x] Sort out the colours.
  - Configure this
    - [ ] Syntax highlighting
- [ ] `code`
  - Configure this
- [ ] `tailscale`
- [-] Alacritty
  - [x] Configure default font to `BlexMono Nerd Font Mono Regular`
  - [x] Mouse Scrolling
  - [x] Right click to copy selection
  - [ ] Hostname ASCII Art
- [ ] `tmux`
  - [ ] Find a session manager I like
  - [ ] Work on visual clarity when paired with `neovim`
- [ ] `sipcalc`
- [-] `oh-my-posh`
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
        Currently, this naively compares the `.Folder` and `.Venv` properties, which returns true if current directory is named the same as the `.venv`.
        Replace this logic with comparing `{{ .Env.VIRTUAL_ENV | dir }}` and `{{ .Segments.Path.Location }}`, when they match, change the `foreground_template` in the path segment to #ffde57.
    - [x] [Secondary Prompt](https://ohmyposh.dev/docs/configuration/secondary-prompt)
      - [x] Show ❯ when in secondary prompt
    - [ ] Tailscale
      - [ ] Show connection

## 3D Modelling
- [ ] `blender`

## Video Production
- [ ] `obs`
- [ ] Da Vinci Resolve

# System Configuration
- [ ] Reduce/Remove timeout from `/boot/grub/grub.cfg`
- [ ] Disable swap
- [ ] Workspace switching keybinds
- [-] Validate microphones work
  - Inputs are combined
- [ ] Validate camera works
- [ ] Unmounting cifs drives, slow on shutdown with `sudo shutdown now`, improve this