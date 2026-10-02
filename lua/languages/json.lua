-- ================================================================================================
-- TITLE : JSON / JSONC / hujson
-- ABOUT : json parser, and jsonls with schemastore schemas (also formats).
-- ================================================================================================

-- JSONC and hujson allow trailing commas; jsonls warns about them unless a matching schema allows them.
-- The list is copied because schemastore returns one shared list, which yaml.lua also reads.
local schemas = vim.list_extend({}, require("schemastore").json.schemas())
table.insert(schemas, { fileMatch = { "*.jsonc", "*.hujson" }, schema = { allowTrailingCommas = true } })

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
					schemas = schemas,
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
