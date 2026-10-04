# Claude Code user-level config. Linked out-of-store because these files are
# written in place: CLAUDE.md is the user-global memory file, and Claude Code
# itself writes settings.json (/config, plugin commands). A read-only store
# symlink would make those writes fail.
#
# The repo's own .claude/settings.json is project scope, so the user-level copy
# is tracked under a different name. See docs/design/claude-settings-split.md
{
  config,
  lib,
  pkgs,
  ...
}:

let
  repo = "${config.home.homeDirectory}/${config.dotfiles.repoPath}";

  # Hook command behind the tmux Claude glyphs. See docs/design/claude-tmux-state.md
  claude-tmux-state = pkgs.writeShellApplication {
    name = "claude-tmux-state";
    runtimeInputs = [
      pkgs.jq
      config.programs.tmux.package
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.libnotify;
    text = builtins.readFile ./files/claude/claude-tmux-state.sh;
  };
in
{
  home.packages = [ claude-tmux-state ];

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/CLAUDE.md";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/user-settings.json";

  # Gitignored, so the flake cannot see it — but mkOutOfStoreSymlink only needs
  # the path. The link is what puts the repo-local marketplace registration in
  # user scope too; the target is created on first write if absent.
  home.file.".claude/settings.local.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/settings.local.json";

  # The personas and the rules they share, linked whole so new agent and rule files appear without a switch.
  home.file.".claude/agents".source = config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/agents";
  home.file.".claude/rules".source = config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/rules";
}
