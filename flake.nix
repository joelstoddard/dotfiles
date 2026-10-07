{
  description = "Unified dotfiles for macOS, Arch Linux (Omarchy), and Debian/Ubuntu — Home Manager flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixpkgs has no opencode v2, and its pi is older than upstream.
    # These flakes keep their own nixpkgs, so their pinned dependency hashes stay valid.
    opencode.url = "github:anomalyco/opencode/v2.0.24";
    pi.url = "github:earendil-works/pi/stable";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      opencode,
      pi,
      ...
    }:
    let
      username = "joel";

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true; # terraform, discord, spotify, steam, obs plugins, davinci-resolve
          overlays = [
            (_: _: {
              opencode = opencode.packages.${system}.opencode;
              pi = pi.packages.${system}.default;
            })
          ];
        };

      mkHome =
        {
          system,
          modules ? [ ],
        }:
        let
          pkgs = mkPkgs system;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home
            {
              home.username = username;
              home.homeDirectory =
                if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";
            }
          ]
          ++ modules;
        };

      # Claude Code writes autoMode — a description of the current environment —
      # into the user-level file, which is this repo's tracked one, in a public
      # repo. Evaluated by `nix flake check`, so --no-build still catches it.
      # See docs/design/claude-settings-split.md
      noAutoMode =
        pkgs:
        if (builtins.fromJSON (builtins.readFile ./.claude/user-settings.json)) ? autoMode then
          throw "autoMode found in .claude/user-settings.json — it belongs in settings.local.json (docs/design/claude-settings-split.md)"
        else
          pkgs.runCommand "no-automode" { } "touch $out";

      # tmux-continuum appends a #() save job to status-right as it loads, and tmux.conf moves
      # that job to a timer. See docs/design/claude-tmux-state.md
      continuumSavesOnTimer =
        pkgs: home:
        let
          inherit (pkgs) lib;
          tmuxConf = home.config.xdg.configFile."tmux/tmux.conf".text;
          afterContinuum =
            if lib.hasInfix "continuum.tmux" tmuxConf then
              lib.last (lib.splitString "continuum.tmux" tmuxConf)
            else
              "";
          lines = lib.splitString "\n";
          beforeTimer = builtins.head (lib.splitString "continuum_save.sh" afterContinuum);
          resets = builtins.filter (
            line: builtins.match " *set(-option)? +-g +status-right +.*" line != null
          ) (lines beforeTimer);
          timers = builtins.filter (
            line: builtins.match " *run-shell -b .*continuum_save\\.sh.*" line != null
          ) (lines afterContinuum);
        in
        if resets != [ ] then
          throw "tmux.conf resets status-right before it moves continuum's save job to a timer, which disables auto-save (#130): ${builtins.head resets}"
        else if timers == [ ] then
          throw "tmux.conf starts no timer for continuum's save job, so status-interval 1 runs the job every second (#168)"
        else
          pkgs.runCommand "continuum-saves-on-timer" { } "touch $out";

      # The Claude glyphs set only a colour, so inactive windows stay dim like the plain dots.
      # See docs/design/claude-tmux-state.md
      claudeGlyphFollowsWindow =
        pkgs: home:
        let
          inherit (pkgs) lib;
          overrides = builtins.filter (
            line:
            lib.hasPrefix "set -g @claude-glyph" line && builtins.match ".*(dim|bold|bright).*" line != null
          ) (lib.splitString "\n" home.config.xdg.configFile."tmux/tmux.conf".text);
        in
        if overrides != [ ] then
          throw "@claude-glyph sets an attribute, so it overrides its window's brightness: ${builtins.head overrides}"
        else
          pkgs.runCommand "claude-glyph-follows-window" { } "touch $out";
    in
    {
      homeConfigurations = {
        # macOS — primary dev machine. GUI apps stay in Homebrew casks (see README).
        "${username}@macos" = mkHome {
          system = "aarch64-darwin";
          modules = [ { dotfiles.gui = false; } ];
        };

        # Arch Linux desktop with Omarchy integration
        "${username}@omarchy" = mkHome {
          system = "x86_64-linux";
          modules = [
            {
              dotfiles.gui = true;
              dotfiles.omarchy = true;
            }
          ];
        };

        # Debian/Ubuntu desktop
        "${username}@linux-desktop" = mkHome {
          system = "x86_64-linux";
          modules = [ { dotfiles.gui = true; } ];
        };

        # Headless server (CLI only)
        "${username}@linux" = mkHome {
          system = "x86_64-linux";
          modules = [ { dotfiles.gui = false; } ];
        };
      };

      # `nix flake check --no-build` evaluates these; CI additionally dry-run builds.
      checks.x86_64-linux = {
        home-linux = self.homeConfigurations."${username}@linux".activationPackage;
        home-linux-desktop = self.homeConfigurations."${username}@linux-desktop".activationPackage;
        home-omarchy = self.homeConfigurations."${username}@omarchy".activationPackage;
        no-automode = noAutoMode (mkPkgs "x86_64-linux");
        continuum-autosave =
          continuumSavesOnTimer (mkPkgs "x86_64-linux")
            self.homeConfigurations."${username}@linux";
        claude-glyph =
          claudeGlyphFollowsWindow (mkPkgs "x86_64-linux")
            self.homeConfigurations."${username}@linux";
      };
      checks.aarch64-darwin = {
        home-macos = self.homeConfigurations."${username}@macos".activationPackage;
        no-automode = noAutoMode (mkPkgs "aarch64-darwin");
        continuum-autosave =
          continuumSavesOnTimer (mkPkgs "aarch64-darwin")
            self.homeConfigurations."${username}@macos";
        claude-glyph =
          claudeGlyphFollowsWindow (mkPkgs "aarch64-darwin")
            self.homeConfigurations."${username}@macos";
      };

      formatter.x86_64-linux = (mkPkgs "x86_64-linux").nixfmt-tree;
      formatter.aarch64-darwin = (mkPkgs "aarch64-darwin").nixfmt-tree;
    };
}
