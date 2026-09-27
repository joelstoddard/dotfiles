-- ================================================================================================
-- TITLE : YAML
-- ABOUT : yaml parser, yamlls with schemastore schemas (also formats), and yamllint.
-- ================================================================================================

return {
	filetypes = { "yaml" },
	parsers = { "yaml" },
	servers = {
		yamlls = {
			filetypes = { "yaml", "yaml.docker-compose", "yaml.helm-values" },
			settings = {
				yaml = {
					schemastore = {
						enable = false,
						url = "",
					},
					schemas = require("schemastore").yaml.schemas(),
					validate = true,
					format = {
						enable = true,
					},
				},
			},
		},
	},
	-- efmls-configs' yamllint parses no severity or column, and efm drops the output when yamllint exits 0
	-- (warnings only). Without these overrides, findings appear as errors at column 0 or not at all.
	lint = {
		vim.tbl_extend("force", require("efmls-configs.linters.yamllint"), {
			lintFormats = { "%f:%l:%c: [%tarning] %m", "%f:%l:%c: [%trror] %m" },
			lintIgnoreExitCode = true,
		}),
	},
	format_with = "yamlls",
	mason = { "yaml-language-server", "yamllint" },
}
