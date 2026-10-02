# oh-my-posh prompt. The theme YAML files are kept verbatim (they contain
# Nerd Font glyphs in the Unicode Private Use Area — never retype them) and
# linked into ~/.config/oh-my-posh. The binary comes from nixpkgs, so the
# theme's self-upgrade block is inert.
{ ... }:

{
  xdg.configFile."oh-my-posh/theme.yaml".source = ./files/oh-my-posh/theme.yaml;
  xdg.configFile."oh-my-posh/claude.yaml".source = ./files/oh-my-posh/claude.yaml;

  # Init by hand rather than via programs.oh-my-posh so we keep the
  # Apple_Terminal guard and the stable ~/.config path.
  programs.zsh.initContent = ''
    if command -v oh-my-posh &>/dev/null && [[ "$TERM_PROGRAM" != "Apple_Terminal" ]]; then
      eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.yaml)"
    fi
  '';
}
