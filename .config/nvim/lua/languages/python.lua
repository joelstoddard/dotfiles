-- ================================================================================================
-- TITLE : Python
-- ABOUT : python parser, pyright, and ruff for lint and format.
-- ================================================================================================

-- efmls-configs uses ruff's GitHub-annotation format, which encodes each message's help line as a literal %0A.
-- The concise format colours its output when FORCE_COLOR or CLICOLOR_FORCE is set, which efm cannot parse.
local ruff = require("efmls-configs.linters.ruff")
return {
	filetypes = { "python" },
	line_length = 88, -- ruff format's line length
	parsers = { "python" },
	servers = {
		pyright = {
			settings = {
				pyright = {
					disableOrganizeImports = false,
					analysis = {
						useLibraryCodeForTypes = true,
						autoSearchPaths = true,
						diagnosticMode = "workspace",
						autoImportCompletions = true,
					},
				},
			},
		},
	},
	lint = {
		vim.tbl_extend("force", ruff, {
			lintCommand = "env -u FORCE_COLOR -u CLICOLOR_FORCE "
				.. ruff.lintCommand:gsub("%-%-output%-format github", "--output-format concise"),
			lintFormats = { "%.%#:%l:%c: %m" },
		}),
	},
	format = { "ruff" },
	mason = { "pyright", "ruff" },
}
