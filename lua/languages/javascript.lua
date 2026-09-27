-- ================================================================================================
-- TITLE : JavaScript
-- ABOUT : javascript parser, eslint_d and prettierd; ts_ls (typescript.lua) serves JavaScript too.
-- ================================================================================================

return {
	filetypes = { "javascript", "javascriptreact" },
	parsers = { "javascript" },
	lint = { "eslint_d" },
	format = { "prettier_d" },
	mason = { "eslint_d", "prettierd" },
}
