-- ================================================================================================
-- TITLE : Helm
-- ABOUT : detects chart templates and values for helm_ls; templates use the helm parser.
-- ================================================================================================

-- The rules only fire inside a chart, so a GitHub Actions templates/ or a stray values.yaml stays YAML.
local function in_chart(dir)
	return vim.uv.fs_stat(dir .. "/Chart.yaml") ~= nil
end

local function template(path)
	local chart = path:match("^(.*)/templates/")
	if chart and in_chart(chart) then
		return "helm"
	end
end

local function values(path)
	if in_chart(vim.fs.dirname(path)) then
		return "yaml.helm-values"
	end
end

return {
	parsers = { "helm" },
	register = { yaml = { "yaml.helm-values" } },
	servers = { helm_ls = {} },
	mason = { "helm-ls" },
	detect = {
		pattern = {
			[".*/templates/.*%.ya?ml"] = template,
			[".*/templates/.*%.tpl"] = template,
			[".*/values[^/]*%.ya?ml"] = values,
		},
	},
}
