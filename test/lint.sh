#!/usr/bin/env bash
# Lint command: Nix formatting, shellcheck, a zsh parse check, actionlint and ruff.
# It re-runs itself in a shell with the flake's locked tools, so local runs and CI use the same versions.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

if [[ -z ${LINT_TOOLS:-} ]]; then
  LINT_TOOLS=1 exec nix shell --inputs-from . nixpkgs#shellcheck nixpkgs#actionlint nixpkgs#ruff nixpkgs#zsh -c bash "$0"
fi

rc=0
nix fmt -- --ci || rc=1
while IFS= read -r f; do
  # zsh scripts get a parse check only, because shellcheck has no zsh mode.
  if [[ $f == *.zsh || $(head -1 "$f") == *zsh* ]]; then zsh -n "$f" || rc=1; else shellcheck "$f" || rc=1; fi
done < <(git ls-files --cached --others --exclude-standard '*.sh' '*.zsh' ':!.config/nvim')
actionlint || rc=1
ruff check test || rc=1
exit $rc
