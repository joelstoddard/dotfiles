-- ================================================================================================
-- TITLE : Go
-- ABOUT : go, gomod and gosum parsers, gopls, revive and gofumpt.
-- ================================================================================================

return {
	filetypes = { "go" },
	parsers = { "go", "gomod", "gosum" },
	servers = { gopls = {} },
	lint = { "go_revive" },
	format = { "gofumpt" },
	mason = { "gopls", "revive", "gofumpt" },
}
