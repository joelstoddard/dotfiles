# Package sets, ported from packages/packages.yaml. One source of truth for
# every platform — nixpkgs replaces pacman/yay, apt (+ custom repos),
# Homebrew formulae, GitHub-release downloads and curl|sh installers.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;

  ttl = pkgs.callPackage ./pkgs/ttl.nix { };

  core =
    with pkgs;
    [
      wget
      curl
      git
      zsh
      tmux
      neovim
      jq
      yq-go
      ripgrep
      grex
      fzf
      cmake
      gnupg
      unzip
      rsync
      tldr
      btop
      fastfetch
      sipcalc
      nmap
      ttl
      oh-my-posh
      bitwarden-cli
      tailscale
      claude-code
      eza
      # nvm is replaced by a Nix-managed Node.js; pin per-project versions with
      # a flake devShell or direnv instead of `nvm use`.
      nodejs_22
      rustup
    ]
    ++ lib.optionals isLinux [
      nettools
    ];

  development =
    with pkgs;
    [
      ansible
      awscli2
      docker # CLI + engine on Linux; on macOS the daemon runs via colima
      go
      kubernetes-helm
      kubectl
      kubectx
      gh
      postgresql # psql client (was libpq)
      rdkafka
      python3
      terraform
      uv
      bash
      lua5_4
    ]
    ++ lib.optionals isDarwin [
      colima
    ];

  work = with pkgs; [
    granted
    jfrog-cli
    # awscurl: not in nixpkgs — install with `uv tool install awscurl`
  ];

  # GUI categories (desktop / gaming / 3d-modelling / streaming-video-production).
  # Linux only: on macOS, GUI apps install poorly through nixpkgs, so casks
  # (firefox, bitwarden, spotify, raycast, linearmouse, alacritty, fonts, …)
  # stay with Homebrew — see README.
  desktop =
    with pkgs;
    lib.optionals (cfg.gui && isLinux) [
      firefox
      bitwarden-desktop
      spotify
      rofi
      # notion: no first-class nixpkgs package; use the web app or keep the
      # AUR/cask install on that machine.
    ];

  gaming =
    with pkgs;
    lib.optionals (cfg.gui && isLinux) [
      discord
      # steam works best as a NixOS module (programs.steam); from Home Manager
      # on a foreign distro, prefer the distro package. The client is still
      # installed here for NixOS hosts.
      steam
    ];

  modelling =
    with pkgs;
    lib.optionals (cfg.gui && isLinux) [
      blender
    ];

  streaming =
    with pkgs;
    lib.optionals (cfg.gui && isLinux) [
      obs-studio
      davinci-resolve
    ];
in
{
  home.packages =
    core ++ development ++ lib.optionals cfg.work work ++ desktop ++ gaming ++ modelling ++ streaming;
}
