-- ================================================================================================
-- TITLE : Bash / sh
-- ABOUT : bash parser, bashls, shellcheck and shfmt.
-- ================================================================================================

return {
	filetypes = { "sh", "bash" },
	parsers = { "bash" },
	servers = { bashls = { filetypes = { "sh", "bash", "zsh" } } },
	format = { "shfmt" },
	-- bashls runs shellcheck itself when it is installed, so efm does not run it a second time.
	mason = { "bash-language-server", "shellcheck", "shfmt" },
}
