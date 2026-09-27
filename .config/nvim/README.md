# NeoVim for DevOps

## Overview

This is a DevOps focussed, minimal, largely monochromatic theme (with a sprinkle of colours) for software development.

Features support for language:

- `ansible`
- `bash` & `zsh`
- `docker` & `docker-compose`
- `go`
- `html`, `css`, `javascript` & `typescript`
- `json` & `jsonc` (With comments)
- `kubectl`,`kubectx`, and `helm`
- `lua`
- `markdown`
- `postgresql`
- `python`
- `terraform`
- `yaml`

## Requirements

- Neovim 0.12 or later (plugins install through the built-in `vim.pack`)
- `tree-sitter` CLI 0.26.1 or later, a C compiler, `curl` and `tar` (to build treesitter parsers)
- `luacheck` (Lua linter; install with your package manager)
- `node`/`npm`, `python3` and `go` (Mason builds servers, linters and formatters with them)
- `terraform` (terraform-ls formats through `terraform fmt`) and `ansible` (ansiblels needs it)
- `git`, `ripgrep` and `fzf`
- A [Nerd Font](https://www.nerdfonts.com/)

The first start installs every plugin and asks for confirmation. Update later with `:lua vim.pack.update()`.
Language servers, linters and formatters install automatically through Mason; see `lua/languages/`.

## License

This config is released under GPLv3.
