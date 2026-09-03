# zsh, ported from .zshrc. Plugin cloning, generated completions
# (scripts/generate_completions.py) and NVM lazy-loading are all replaced by
# Nix: packages ship their zsh completions into the profile's
# share/zsh/site-functions, which Home Manager puts on fpath.
{ config, pkgs, ... }:

{
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "$HOME/.sops/key.txt";
    ZSH_TMUX_FIXTERM = "false"; # ZSH tmux plugin compat
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
  ];

  # fzf key bindings (Ctrl-R history, Ctrl-T files, Alt-C cd) + completion
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;

    history = {
      size = 1000;
      save = 1000;
      path = "${config.home.homeDirectory}/.zsh_history";
      share = true;
      append = true;
      ignoreSpace = true;
      ignoreDups = true;
      ignoreAllDups = true;
      saveNoDups = true;
      findNoDups = true;
    };

    shellAliases = {
      ls = "eza -lh --group-directories-first --icons=auto";
      lsa = "ls -a";
      lt = "eza --tree --level=2 --long --icons --git";
      lta = "lt -a";
    };

    initContent = ''
      # ==========================================================================
      # Key Bindings
      # ==========================================================================
      bindkey '^[[3;5~' backward-kill-word     # Ctrl+Backspace
      bindkey '^[[1;5D' backward-word          # Ctrl+Left
      bindkey '^[[1;5C' forward-word           # Ctrl+Right

      # ==========================================================================
      # Tool Init
      # ==========================================================================

      # Homebrew (macOS — still used for GUI casks). shellenv prepends
      # /opt/homebrew/bin, which would shadow the CLI tools nixpkgs owns, so put
      # the Nix profile back in front. typeset -U keeps the re-add from
      # duplicating entries on a nested shell.
      if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        typeset -U path
        path=("$HOME/.nix-profile/bin" "/nix/var/nix/profiles/default/bin" $path)
      fi

      # GPG
      export GPG_TTY=$(tty)

      # ==========================================================================
      # Shell Integrations
      # ==========================================================================

      # command-not-found — suggest installable packages when a command is missing
      # Debian/Ubuntu ship /etc/zsh_command_not_found; Arch provides it via pkgfile
      for f in /etc/zsh_command_not_found /usr/share/doc/pkgfile/command-not-found.zsh; do
        [[ -r "$f" ]] && source "$f" && break
      done

      # bash-style completers (aws, terraform)
      autoload -U +X bashcompinit && bashcompinit

      # AWS CLI tab completion via the official aws_completer
      if command -v aws_completer &>/dev/null; then
        complete -C "$(command -v aws_completer)" aws
      fi

      # Terraform tab completion
      if command -v terraform &>/dev/null; then
        complete -o nospace -C "$(command -v terraform)" terraform
      fi

      # JFrog CLI completion
      if command -v jfrog &>/dev/null; then
        _jfrog() {
          local -a opts
          opts=("''${(@f)$(_CLI_ZSH_AUTOCOMPLETE_HACK=1 ''${words[@]:0:#words[@]-1} --generate-bash-completion)}")
          _describe 'values' opts
          if [[ $compstate[nmatches] -eq 0 && $words[$CURRENT] != -* ]]; then
            _files
          fi
        }
        compdef _jfrog jfrog
        compdef _jfrog jf
      fi

      # List configured AWS profiles (helper function, not an alias)
      aws_profiles() {
        grep -h -Eo '\[(profile[[:space:]]+)?[^]]+\]' \
          "''${AWS_CONFIG_FILE:-$HOME/.aws/config}" \
          "''${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}" 2>/dev/null \
          | sed -E 's/^\[(profile[[:space:]]+)?//; s/\]$//' \
          | grep -v '^granted_registry_' \
          | sort -u
      }

      # ==========================================================================
      # Auto-activate project environments on chpwd
      # ==========================================================================
      [[ -r "$HOME/.config/zsh/autoenv.zsh" ]] && source "$HOME/.config/zsh/autoenv.zsh"
    '';
  };

  # autoenv: on chpwd, dispatch to per-language handlers (see files/zsh/)
  xdg.configFile."zsh/autoenv.zsh".source = ./files/zsh/autoenv.zsh;
  xdg.configFile."zsh/autoenv.d/python.zsh".source = ./files/zsh/autoenv.d/python.zsh;
}
