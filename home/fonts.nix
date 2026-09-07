# Fonts (was ibm-plex-mono / atkinson-hyperlegible in packages.yaml).
# Linux only — on macOS the nerd-font casks stay in Homebrew.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (config.dotfiles.gui && pkgs.stdenv.hostPlatform.isLinux) {
    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      nerd-fonts.blex-mono # IBM Plex Mono Nerd Font
      nerd-fonts.atkynson-mono # Atkinson Hyperlegible Nerd Font
      atkinson-hyperlegible
    ];
  };
}
