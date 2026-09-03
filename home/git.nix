# git, ported from .config/git/config. Colors come from the shared palette.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  palette = config.dotfiles.palette;
in
{
  # Conventional-commit template (was .config/git/template)
  xdg.configFile."git/template".text = ''
    # fix:
    # feat:
    # chore:
    # docs:
    # style:
    # refactor:
    # perf:
    # test:
    # build:
    # ci:
    #
    # https://www.conventionalcommits.org/en/v1.0.0/
  '';

  programs.git = {
    enable = true;

    signing = {
      key = "83C041427307B6AB";
      signByDefault = true;
    };

    # Global excludes (was .config/git/ignore)
    ignores = [
      "# Python specific"
      ".venv/"
      ".pytest_cache/"
      "__pycache__/"
      "**/.claude/settings.local.json"
      ""
      "# Claude Code worktrees, specs and plans (kept local, not versioned)"
      "**/.claude/specs/"
      "**/.claude/plans/"
      "**/.claude/worktrees/"
    ];

    settings = {
      user = {
        name = "Joel Stoddard-Turvey";
        email = "93982886+joelstoddard@users.noreply.github.com";
      };

      commit = {
        template = "${config.xdg.configHome}/git/template";
        verbose = true;
      };

      core = {
        autocrlf = "input";
        whitespace = "error";
        preloadindex = true;
        editor = "nvim";
      };

      blame = {
        coloring = "highlightRecent";
        date = "relative";
      };

      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        colorMovedWS = "allow-indentation-change";
        mnemonicPrefix = true;
        renames = "copies";
        context = 3;
        interHunkContext = 10;
        tool = "nvimdiff";
      };

      difftool = {
        prompt = true;
        nvimdiff.cmd = ''nvim -d "$LOCAL" "$REMOTE"'';
      };

      interactive.singlekey = true;
      init.defaultBranch = "main";
      log.graphColors = "white dim";

      status = {
        branch = true;
        short = true;
        showStash = true;
        showUntrackedFiles = "all";
      };

      push = {
        autoSetupRemote = true;
        default = "current";
      };

      pull = {
        rebase = true;
        default = "current";
      };

      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
        missingCommitsCheck = "warn";
      };

      transfer.fsckObjects = true;
      receive.fsckObjects = true;

      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
        fsckObjects = true;
      };

      remote.origin.fetch = "+refs/tags/*:refs/tags/*";
      help.autocorrect = "prompt";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      column.ui = "auto";

      format = {
        pretty = ''format:%C("${palette.semantic.git}")%h%Creset: %C(white dim)%ar by %aN %Creset %n%C(white)%s%n%Creset'';
        date = "relative";
      };

      color = {
        blame.highlightRecent = "black bold,1 year ago,white,1 month ago,default,7 days ago,blue";

        branch = {
          current = palette.semantic.git;
          local = "white";
          remote = "white dim";
          upstream = "white dim";
          plain = "white dim";
        };

        diff = {
          meta = palette.base.muted;
          frag = palette.base.muted;
          func = "${palette.base.muted} dim";
          context = "white dim";
          new = palette.semantic.success;
          old = palette.semantic.error;
          newMoved = palette.accent.purple;
          oldMoved = palette.accent.purple;
          whitespace = "${palette.semantic.error} reverse";
        };
      };
    };
  };
}
