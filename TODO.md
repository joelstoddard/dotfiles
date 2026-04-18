# TODO

## Oh-My-Posh Segments
- [x] [SSH](https://ohmyposh.dev/docs/segments/system/session) — show hostname when connected via SSH
- [ ] Context-aware icons — show tool icons when in relevant repo directories:
  - [ ] AWS (when in AWS repo/folder)
  - [ ] Terraform (when .terraform/ exists)
  - [ ] Kubernetes (when in k8s repo/folder)
  - [ ] Docker (when Dockerfile exists)
  - [ ] Helm (when Chart.yaml exists)
  - [ ] Claude 󰯉 (when CLAUDE.md exists)

## Shell
- [ ] `chpwd` hook for auto-activating Python venvs on directory change
- [ ] Explore [sheldon](https://github.com/rossmacarthur/sheldon) as alternative to manual plugin loading

## Tmux
- [ ] Auto-start tmux on interactive shell
- [ ] Visual clarity improvements when paired with neovim
- [ ] Adjust scroll sensitivity
- [ ] Ctrl+click for links (terminal emulator dependent)

## Tools
- [ ] btop configuration (GPU monitoring, theme)
- [ ] Hostname ASCII art in Alacritty (fastfetch integration)

## System Configuration (Linux)
- [ ] Reduce/remove GRUB timeout
- [ ] Disable swap
- [ ] Workspace switching keybinds
- [ ] ddccontrol brightness automation (day/evening/night)
- [ ] fprintd fingerprint setup

## Testing
- [ ] GitHub Actions CI workflow (`.github/workflows/test.yml`)
- [ ] macOS runner in CI matrix
