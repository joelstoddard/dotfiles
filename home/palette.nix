# ash-plus palette — single source of truth for theme colors.
# Ash monochrome base for terminal surfaces / ANSI defaults; vivid colors are
# reserved for tool signals (accent / semantic). Ported from theme/palette.yaml.
{ lib, ... }:

{
  options.dotfiles.palette = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
    readOnly = true;
    description = "ash-plus color palette used by alacritty, git, tmux and oh-my-posh.";
  };

  config.dotfiles.palette = {
    base = {
      bg = "#121212";
      bg-soft = "#1a1a1a";
      fg = "#e0e0e0";
      fg-bright = "#ffffff";
      muted = "#8a8a8a";
      dim = "#626262";
    };

    accent = {
      orange = "#F79625";
      yellow = "#FFDE57";
      green = "#90A959";
      red = "#AC4242";
      blue = "#326CE5";
      purple = "#AA759F";
    };

    semantic = {
      git = "#F79625";
      python = "#FFDE57";
      error = "#AC4242";
      success = "#90A959";
      info = "#326CE5";
      aws = "#FFA400";
      docker = "#0B59E7";
      k8s = "#326CE5";
      terraform = "#EBCC34";
    };
  };
}
