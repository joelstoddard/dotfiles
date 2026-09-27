-- ================================================================================================
-- TITLE : Dockerfile
-- ABOUT : dockerfile parser, dockerls and hadolint.
-- ================================================================================================

return {
	filetypes = { "dockerfile" },
	parsers = { "dockerfile" },
	servers = { dockerls = {} },
	lint = { "hadolint" },
	mason = { "dockerfile-language-server", "hadolint" },
}
