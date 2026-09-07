# Claude Code user-level config. Linked out-of-store because these files are
# written in place: CLAUDE.md is the user-global memory file, and Claude Code
# itself writes settings.json (/config, plugin commands). A read-only store
# symlink would make those writes fail.
#
# The repo's own .claude/settings.json is project scope, so the user-level copy
# is tracked under a different name. See docs/design/claude-settings-split.md
{ config, ... }:

let
  repo = "${config.home.homeDirectory}/${config.dotfiles.repoPath}";
in
{
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/CLAUDE.md";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/user-settings.json";

  # Gitignored, so the flake cannot see it — but mkOutOfStoreSymlink only needs
  # the path. The link is what puts the repo-local marketplace registration in
  # user scope too; the target is created on first write if absent.
  home.file.".claude/settings.local.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/settings.local.json";
}
