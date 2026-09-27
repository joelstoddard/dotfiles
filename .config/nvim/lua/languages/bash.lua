-- ================================================================================================
-- TITLE : Bash / sh
-- ABOUT : bash parser, bashls, shellcheck and shfmt.
-- ================================================================================================

return {
	filetypes = { "sh", "bash" },
	parsers = { "bash" },
	servers = { bashls = { filetypes = { "sh", "bash", "zsh" } } },
	lint = { "shellcheck" },
	format = { "shfmt" },
	mason = { "bash-language-server", "shellcheck", "shfmt" },
}
