-- ================================================================================================
-- TITLE : CSS
-- ABOUT : css parser, cssls and prettierd.
-- ================================================================================================

return {
	filetypes = { "css" },
	line_length = 80, -- prettier's print width
	parsers = { "css" },
	servers = { cssls = {} },
	format = { "prettier_d" },
	mason = { "css-lsp", "prettierd" },
}
