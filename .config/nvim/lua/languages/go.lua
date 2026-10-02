-- ================================================================================================
-- TITLE : Go
-- ABOUT : go, gomod and gosum parsers, gopls, revive and gofumpt.
-- ================================================================================================

-- revive exits 0 when it reports problems, and efm drops that output. revive cannot read stdin, so it lints the saved file.
local revive = require("efmls-configs.linters.go_revive")
return {
	filetypes = { "go" },
	parsers = { "go", "gomod", "gosum" },
	servers = { gopls = {} },
	lint = {
		vim.tbl_extend("force", revive, {
			lintCommand = revive.lintCommand .. " '${INPUT}'",
			lintStdin = false,
			lintIgnoreExitCode = true,
		}),
	},
	format = { "gofumpt" },
	mason = { "gopls", "revive", "gofumpt" },
}
