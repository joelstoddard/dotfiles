{ lib, ... }:

{
  imports = [
    ./palette.nix
    ./packages.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix
    ./oh-my-posh.nix
    ./alacritty.nix
    ./btop.nix
    ./nvim.nix
    ./fonts.nix
  ];

  options.dotfiles = {
    gui = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install GUI applications (desktop, gaming, streaming, 3d-modelling categories).";
    };

    omarchy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Arch Linux Omarchy integration (imports the Omarchy Alacritty theme).";
    };

    work = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install work packages (granted, jfrog-cli, awscurl).";
    };

    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "personal/dotfiles";
      description = ''
        Path of this repo checkout relative to $HOME. Used for the Neovim
        config out-of-store symlink so lazy.nvim can write lazy-lock.json.
      '';
    };
  };

  config = {
    programs.home-manager.enable = true;

    # Bump only when Home Manager release notes require action.
    home.stateVersion = "25.05";
  };
}
