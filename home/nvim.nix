# Neovim. The config in .config/nvim is a git subtree managed in a separate
# repo (~/personal/nvim) — DO NOT edit it here. It is linked out-of-store so
# lazy.nvim can write lazy-lock.json next to init.lua.
{ config, ... }:

{
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${config.dotfiles.repoPath}/.config/nvim";
}
