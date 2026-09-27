-- ================================================================================================
-- TITLE : JSON / JSONC / hujson
-- ABOUT : json parser, and jsonls with schemastore schemas (also formats).
-- ================================================================================================

-- nvim-treesitter has no jsonc parser, so jsonc and hujson reuse json's.
return {
	filetypes = { "json", "jsonc" },
	parsers = { "json" },
	register = { json = { "jsonc" } },
	servers = {
		jsonls = {
			filetypes = { "json", "jsonc" },
			settings = {
				json = {
					schemas = require("schemastore").json.schemas(),
					validate = { enable = true },
				},
			},
		},
	},
	-- jsonls keeps comments and trailing commas, which fixjson strips from jsonc and hujson files.
	format_with = "jsonls",
	mason = { "json-lsp" },
	detect = { extension = { hujson = "jsonc" } },
}
