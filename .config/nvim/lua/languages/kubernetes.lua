-- ================================================================================================
-- TITLE : Kubernetes
-- ABOUT : yaml.kubernetes for manifests, served by a yamlls that applies only the Kubernetes schema.
-- ================================================================================================

-- yamlls cannot exclude files from a schema glob, and it applies every schema that matches. So path globs also put
-- the Kubernetes schema on compose, Helm and kustomize files.
local yaml = require("languages.yaml")

-- A manifest has top-level apiVersion and kind. Kustomize files and Helm templates have them too, but belong to
-- other tools.
local function manifest(path, bufnr)
	if not bufnr or vim.fs.basename(path):match("^kustomization%.ya?ml$") then
		return
	end
	local chart = path:match("^(.*)/templates/")
	if chart and vim.uv.fs_stat(chart .. "/Chart.yaml") then
		return
	end
	local api, kind = false, false
	for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
		api = api or line:find("^apiVersion:") ~= nil
		kind = kind or line:find("^kind:") ~= nil
	end
	if api and kind then
		return "yaml.kubernetes"
	end
end

return {
	filetypes = { "yaml.kubernetes" },
	register = { yaml = { "yaml.kubernetes" } },
	servers = {
		yamlls_kubernetes = {
			cmd = { "yaml-language-server", "--stdio" },
			filetypes = { "yaml.kubernetes" },
			root_markers = { ".git" },
			settings = {
				redhat = { telemetry = { enabled = false } },
				yaml = {
					schemastore = { enable = false, url = "" },
					schemas = { kubernetes = "*" },
					validate = true,
					format = { enable = true },
				},
			},
			-- Matches lspconfig's yamlls, which enables formatting the same way.
			on_init = function(client)
				client.server_capabilities.documentFormattingProvider = true
			end,
		},
	},
	lint = yaml.lint,
	line_length = yaml.line_length,
	format_with = "yamlls_kubernetes",
	detect = {
		pattern = {
			[".*/k8s/.*%.ya?ml"] = manifest,
			[".*/kubernetes/.*%.ya?ml"] = manifest,
			[".*/manifests/.*%.ya?ml"] = manifest,
			[".*/deploy/.*%.ya?ml"] = manifest,
			[".*%.k8s%.ya?ml"] = "yaml.kubernetes",
		},
	},
}
