-- ================================================================================================
-- TITLE : Docker Compose
-- ABOUT : detects compose files as yaml.docker-compose for the compose language server (yamlls too).
-- ================================================================================================

local compose = "yaml.docker-compose"

return {
	register = { yaml = { compose } },
	servers = { docker_compose_language_service = {} },
	mason = { "docker-compose-language-service" },
	detect = {
		pattern = {
			[".*/docker%-compose[^/]*%.ya?ml"] = compose,
			[".*/compose[^/]*%.ya?ml"] = compose,
		},
	},
}
