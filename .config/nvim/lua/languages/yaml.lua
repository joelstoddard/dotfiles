-- ================================================================================================
-- TITLE : YAML
-- ABOUT : yaml parser, yamlls with schemastore schemas (also formats), and yamllint.
-- ================================================================================================

local yamllint = require("efmls-configs.linters.yamllint")
local line_length = 120
-- yamllint's defaults flag every file without a "---" line and treat lines past 80 columns as errors.
local yamllint_config = ("{extends: default, rules: {document-start: disable, line-length: {max: %d, level: warning}}}"):format(line_length)

return {
	filetypes = { "yaml" },
	line_length = line_length,
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
		vim.tbl_extend("force", yamllint, {
			lintCommand = (yamllint.lintCommand:gsub("%-f parsable", "%0 -d '" .. yamllint_config .. "'")),
			lintFormats = { "%f:%l:%c: [%tarning] %m", "%f:%l:%c: [%trror] %m" },
			lintIgnoreExitCode = true,
		}),
	},
	format_with = "yamlls",
	mason = { "yaml-language-server", "yamllint" },
}
