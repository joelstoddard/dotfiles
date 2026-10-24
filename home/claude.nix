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

  # Claude Code hooks call this command to set the tmux Claude state. See docs/design/claude-tmux-state.md
  claude-tmux-state = pkgs.writeShellApplication {
    name = "claude-tmux-state";
    runtimeInputs = [
      pkgs.jq
      config.programs.tmux.package
    ]
    ++ lib.optional (pkgs.stdenv.hostPlatform.isLinux && config.dotfiles.gui) pkgs.libnotify;
    text = builtins.readFile ./files/claude/claude-tmux-state.sh;
  };

  claude-notify-plist = pkgs.writeText "Info.plist" (
    lib.generators.toPlist { escape = true; } {
      CFBundleIdentifier = "local.dotfiles.claude-notify";
      CFBundleName = "Claude Code";
      CFBundleExecutable = "claude-notify";
      CFBundleIconFile = "AppIcon";
      CFBundlePackageType = "APPL";
      LSUIElement = true;
    }
  );
in
{
  home.packages = [ claude-tmux-state ];

  # The app claude-tmux-state notifies through on macOS. It is built in ~/Applications, where
  # macOS accepts it, with the icon from Claude.app. See docs/design/claude-tmux-state.md
  home.activation.claudeNotify = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      app="$HOME/Applications/Claude Notify.app"
      icon=/Applications/Claude.app/Contents/Resources/electron.icns
      if /usr/bin/xcode-select -p >/dev/null 2>&1; then
        run rm -rf "$app"
        run mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
        run /usr/bin/swiftc -O -o "$app/Contents/MacOS/claude-notify" ${./files/claude/claude-notify.swift}
        run cp ${claude-notify-plist} "$app/Contents/Info.plist"
        if [ -f "$icon" ]; then run cp "$icon" "$app/Contents/Resources/AppIcon.icns"; fi
        run /usr/bin/codesign --force --sign - "$app"
        run /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
      else
        warnEcho "No Command Line Tools, so Claude notifications keep Script Editor's icon: run xcode-select --install"
      fi
    ''
  );

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/CLAUDE.md";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/user-settings.json";

  # Gitignored, so the flake cannot see it — but mkOutOfStoreSymlink only needs
  # the path. The link puts machine-local settings, such as work marketplaces, in
  # user scope too; the target is created on first write if absent.
  home.file.".claude/settings.local.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/settings.local.json";

  # Path-scoped rules and the personal context, linked whole so new rule files appear without a switch.
  home.file.".claude/rules".source = config.lib.file.mkOutOfStoreSymlink "${repo}/.claude/rules";
}
