-- ================================================================================================
-- TITLE : Markdown
-- ABOUT : markdown parsers, marksman, markdownlint and prettierd.
-- ================================================================================================

-- Markdown buffers soft-wrap, so MD013 (lines past 80 columns) flags almost every paragraph of prose.
local markdownlint = require("efmls-configs.linters.markdownlint")
return {
	filetypes = { "markdown" },
	parsers = { "markdown", "markdown_inline" },
	servers = { marksman = {} },
	lint = { vim.tbl_extend("force", markdownlint, { lintCommand = markdownlint.lintCommand .. " --disable MD013" }) },
	format = { "prettier_d" },
	mason = { "marksman", "markdownlint", "prettierd" },
}
