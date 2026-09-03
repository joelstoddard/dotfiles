# Alacritty, ported from .config/alacritty/*.toml. The old installer-created
# os.toml symlink is replaced by Nix conditionals; colors.toml generation is
# replaced by the palette module.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles;
  palette = config.dotfiles.palette;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

  # Control characters (Nix has no \u string escapes; JSON does)
  esc = builtins.fromJSON ''"\u001b"''; # ESC
  ctrlW = builtins.fromJSON ''"\u0017"''; # Ctrl-W

  # Same character class as the old configs, written with \x escapes so no
  # raw control bytes end up in the generated TOML.
  hintsRegex = "(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https://|http://|news:|file:|git://|ssh:|ftp://)[^\\x00-\\x1F\\x7F-\\x9F<>\"\\s{-}\\^⟨⟩`]+";

  urlOpener = if isDarwin then "open" else "xdg-open";

  sharedKeyboardBindings = [
    {
      key = "Insert";
      mods = "Shift";
      action = "Paste";
    }
    {
      key = "Insert";
      mods = "Control";
      action = "Copy";
    }
    {
      key = "Return";
      mods = "Shift";
      chars = "${esc}\r";
    }
  ];

  darwinKeyboardBindings = [
    {
      key = "Left";
      mods = "Command";
      action = "WordLeft";
    }
    {
      key = "Right";
      mods = "Command";
      action = "WordRight";
    }
    {
      key = "Backspace";
      mods = "Command";
      chars = ctrlW;
    }
    {
      key = "Delete";
      mods = "Command";
      chars = "${esc}d";
    }
  ];
in
{
  # On macOS the app itself ships via Homebrew cask, so only the config is
  # managed there; on Linux the package comes from nixpkgs.
  programs.alacritty = {
    enable = true;
    package = lib.mkIf isDarwin pkgs.emptyDirectory;

    settings = lib.mkMerge [
      {
        # Omarchy themes override the palette on Arch
        general.import = lib.optionals cfg.omarchy [
          "~/.config/omarchy/current/theme/alacritty.toml"
        ];

        env.TERM = "xterm-256color";

        window = {
          title = "Terminal";
          dynamic_title = true;
          decorations = if isDarwin then "Full" else "None";
        }
        // lib.optionalAttrs isLinux {
          padding = {
            x = 14;
            y = 14;
          };
        };

        scrolling = {
          history = 10000;
          multiplier = 2;
        };

        font = {
          normal = {
            family = "BlexMono Nerd Font Mono";
            style = "Regular";
          };
          bold = {
            family = "BlexMono Nerd Font Mono";
            style = "Bold";
          };
          italic = {
            family = "BlexMono Nerd Font Mono";
            style = "Italic";
          };
          size = if isDarwin then 20 else 9;
        };

        mouse.bindings = [
          {
            mouse = "Right";
            mods = "Shift";
            action = "Paste";
          }
          {
            mouse = "Right";
            action = "Copy";
          }
        ];

        keyboard.bindings = sharedKeyboardBindings ++ lib.optionals isDarwin darwinKeyboardBindings;

        hints.enabled = [
          {
            regex = hintsRegex;
            hyperlinks = true;
            post_processing = true;
            mouse = {
              enabled = true;
              mods = "Shift";
            };
            command = urlOpener;
          }
        ];
      }

      # Colors (was generated colors.toml)
      {
        colors = with palette; {
          primary = {
            background = base.bg;
            foreground = base.fg;
          };
          cursor = {
            cursor = base.fg;
            text = base.bg;
          };
          selection = {
            background = base.bg-soft;
            foreground = base.fg-bright;
          };
          normal = {
            black = base.bg;
            red = base.muted;
            green = base.dim;
            yellow = base.muted;
            blue = base.dim;
            magenta = base.muted;
            cyan = base.dim;
            white = base.fg;
          };
          bright = {
            black = base.muted;
            red = base.fg;
            green = base.dim;
            yellow = base.fg;
            blue = base.dim;
            magenta = base.muted;
            cyan = base.fg;
            white = base.fg-bright;
          };
        };
      }
    ];
  };
}
