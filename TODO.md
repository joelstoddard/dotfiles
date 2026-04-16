# TODO

## Oh-My-Posh Segments
- [ ] [SSH](https://ohmyposh.dev/docs/segments/system/session) — show hostname when connected via SSH
- [ ] [Helm](https://ohmyposh.dev/docs/segments/cli/helm) — show chart icon in helm directories
- [ ] [ArgoCD](https://ohmyposh.dev/docs/segments/cli/argocd) — show current context
- [ ] Tailscale — custom command segment showing connection status
- [ ] Claude — show current model/context (pending CLI support)
- [ ] Context-aware icons — show tool icons when in relevant repo directories:
  - [ ] AWS (when in AWS repo/folder)
  - [ ] Terraform (when .terraform/ exists)
  - [ ] Kubernetes (when in k8s repo/folder)
  - [ ] Docker (when Dockerfile exists)

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
