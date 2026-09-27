-- ================================================================================================
-- TITLE : TypeScript / TSX
-- ABOUT : typescript and tsx parsers, ts_ls (also for JavaScript), eslint_d and prettierd.
-- ================================================================================================

return {
	filetypes = { "typescript", "typescriptreact" },
	parsers = { "typescript", "tsx" },
	servers = {
		ts_ls = {
			filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
			settings = {
				typescript = {
					indentStyle = "space",
					indentSize = 2,
				},
			},
		},
	},
	lint = { "eslint_d" },
	format = { "prettier_d" },
	mason = { "typescript-language-server", "eslint_d", "prettierd" },
}
