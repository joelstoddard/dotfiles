{
  description = "Unified dotfiles for macOS, Arch Linux (Omarchy), and Debian/Ubuntu — Home Manager flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      username = "joel";

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true; # terraform, discord, spotify, steam, obs plugins, davinci-resolve
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

      # tmux-continuum saves through a #() job that it appends to status-right as it loads.
      # Nothing after its run-shell may reset status-right. See #130
      continuumKeepsStatusRight =
        pkgs: home:
        let
          inherit (pkgs) lib;
          tmuxConf = home.config.xdg.configFile."tmux/tmux.conf".text;
          afterContinuum =
            if lib.hasInfix "continuum.tmux" tmuxConf then
              lib.last (lib.splitString "continuum.tmux" tmuxConf)
            else
              "";
          resets = builtins.filter (
            line: builtins.match " *set(-option)? +-g +status-right +.*" line != null
          ) (lib.splitString "\n" afterContinuum);
        in
        if resets != [ ] then
          throw "tmux.conf resets status-right after tmux-continuum loads, which disables auto-save (#130): ${builtins.head resets}"
        else
          pkgs.runCommand "continuum-keeps-status-right" { } "touch $out";

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
          continuumKeepsStatusRight (mkPkgs "x86_64-linux")
            self.homeConfigurations."${username}@linux";
        claude-glyph =
          claudeGlyphFollowsWindow (mkPkgs "x86_64-linux")
            self.homeConfigurations."${username}@linux";
      };
      checks.aarch64-darwin = {
        home-macos = self.homeConfigurations."${username}@macos".activationPackage;
        no-automode = noAutoMode (mkPkgs "aarch64-darwin");
        continuum-autosave =
          continuumKeepsStatusRight (mkPkgs "aarch64-darwin")
            self.homeConfigurations."${username}@macos";
        claude-glyph =
          claudeGlyphFollowsWindow (mkPkgs "aarch64-darwin")
            self.homeConfigurations."${username}@macos";
      };

      formatter.x86_64-linux = (mkPkgs "x86_64-linux").nixfmt-tree;
      formatter.aarch64-darwin = (mkPkgs "aarch64-darwin").nixfmt-tree;
    };
}
