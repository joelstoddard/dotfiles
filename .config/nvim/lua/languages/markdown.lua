-- ================================================================================================
-- TITLE : Markdown
-- ABOUT : markdown parsers, marksman, markdownlint and prettierd.
-- ================================================================================================

return {
	filetypes = { "markdown" },
	parsers = { "markdown", "markdown_inline" },
	servers = { marksman = {} },
	lint = { "markdownlint" },
	format = { "prettier_d" },
	mason = { "marksman", "markdownlint", "prettierd" },
}
