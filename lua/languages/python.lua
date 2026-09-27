-- ================================================================================================
-- TITLE : Python
-- ABOUT : python parser, pyright, and ruff for lint and format.
-- ================================================================================================

return {
	filetypes = { "python" },
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
	lint = { "ruff" },
	format = { "ruff" },
	mason = { "pyright", "ruff" },
}
