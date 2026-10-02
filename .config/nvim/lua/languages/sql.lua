-- ================================================================================================
-- TITLE : SQL / PostgreSQL
-- ABOUT : sql parser, postgres_lsp, and sqlfluff (postgres dialect) for lint and format.
-- ================================================================================================

-- efmls-configs hard-codes the ANSI dialect.
local lint = require("efmls-configs.linters.sqlfluff")

return {
	filetypes = { "sql" },
	line_length = 80, -- sqlfluff's LT05 limit
	parsers = { "sql" },
	servers = {
		-- Upstream requires a postgres-language-server.jsonc; without one it still parses and lints.
		postgres_lsp = {
			root_markers = { "postgres-language-server.jsonc", ".git" },
			workspace_required = false,
		},
	},
	lint = { vim.tbl_extend("force", lint, { lintCommand = (lint.lintCommand:gsub("%-%-dialect ansi", "--dialect postgres")) }) },
	-- Not efmls-configs' formatter: its `--ignore ${INPUT}` swallows the path, so sqlfluff rewrites every SQL file in
	-- the directory. Formatting the buffer through stdin touches nothing else.
	format = {
		{
			formatCommand = "sqlfluff format --dialect postgres --nocolor --disable-progress-bar --stdin-filename '${INPUT}' -",
			formatStdin = true,
		},
	},
	mason = { "postgres-language-server", "sqlfluff" },
}
