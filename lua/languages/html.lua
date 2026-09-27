-- ================================================================================================
-- TITLE : HTML
-- ABOUT : html parser, html language server and prettierd.
-- ================================================================================================

return {
	filetypes = { "html" },
	parsers = { "html" },
	servers = { html = {} },
	format = { "prettier_d" },
	mason = { "html-lsp", "prettierd" },
}
