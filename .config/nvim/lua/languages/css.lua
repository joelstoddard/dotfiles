-- ================================================================================================
-- TITLE : CSS
-- ABOUT : css parser, cssls and prettierd.
-- ================================================================================================

return {
	filetypes = { "css" },
	parsers = { "css" },
	servers = { cssls = {} },
	format = { "prettier_d" },
	mason = { "css-lsp", "prettierd" },
}
