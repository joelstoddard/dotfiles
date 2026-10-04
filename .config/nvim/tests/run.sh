#!/bin/sh
# Runs the test suite on this checkout's config, with plugins and tools from a separate install in nvim-test's
# data folder. Usage: sh tests/run.sh [--update] [tests/test_<area>.lua]
set -eu

update=0
if [ "${1:-}" = "--update" ]; then
	update=1
	shift
fi

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

data="${XDG_DATA_HOME:-$HOME/.local/share}/nvim-test"
mkdir -p "$tmp/config/nvim-test" "$tmp/state" "$tmp/cache" "$tmp/work"
# A copy, not a link: vim.pack writes this file, and a normal run must never change the committed lockfile.
cp "$root/nvim-pack-lock.json" "$tmp/config/nvim-test/nvim-pack-lock.json"
export NVIM_APPNAME=nvim-test NVIM_TEST_ROOT="$root" NVIM_TEST_DATA="$data" NVIM_TEST_UPDATE="$update"
export XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state" XDG_CACHE_HOME="$tmp/cache"

# An uncaught Lua error in a -c command leaves headless nvim running instead of exiting. pcall and cquit turn that
# error into a non-zero exit.
bootstrap='local ok, err = pcall(dofile, vim.env.NVIM_TEST_ROOT .. "/tests/bootstrap.lua"); if not ok then io.stderr:write(tostring(err), "\n"); vim.cmd("cquit 1") end'

# The bootstrap starts in an empty folder, so a Session.vim in the checkout is never restored. The config folder
# belongs to the test install, so the checkout reaches nvim only through -u and this runtimepath entry.
if ! (cd "$tmp/work" && nvim --headless --cmd "lua vim.opt.rtp:prepend(vim.env.NVIM_TEST_ROOT)" -u "$root/init.lua" -c "lua $bootstrap"); then
	echo "tests/run.sh: the bootstrap failed (see above); rerun to resume" >&2
	exit 2
fi

# --update is the only path that writes the committed lockfile, and only once the bootstrap's update has succeeded.
if [ "$update" = 1 ]; then
	cp "$tmp/config/nvim-test/nvim-pack-lock.json" "$root/nvim-pack-lock.json"
fi

# The file argument and the data path go through the environment, not into Lua source. A quote or a space in
# either then cannot break the Lua chunk.
export NVIM_TEST_FILE="${1:-}"
run='if vim.env.NVIM_TEST_FILE then MiniTest.run_file(vim.env.NVIM_TEST_FILE) else MiniTest.run() end'
# Setup and the run share one pcall, so a missing test file or a load error also exits non-zero. Two separate -c
# commands could leave nvim open after the first one fails.
suite="local ok, err = pcall(function() require('mini.test').setup(); $run end); if not ok then io.stderr:write(tostring(err), \"\n\"); vim.cmd('cquit 1') end"
cd "$root"
nvim --headless --clean --cmd "lua vim.opt.packpath:prepend(vim.env.NVIM_TEST_DATA .. '/site')" -c "packadd mini.nvim" -c "lua $suite"
