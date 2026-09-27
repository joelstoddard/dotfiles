-- ================================================================================================
-- TITLE : Kubernetes
-- ABOUT : applies yamlls's kubernetes schema to manifest paths; merged into yaml.lua's yamlls.
-- ================================================================================================

return {
	servers = {
		yamlls = {
			settings = {
				yaml = {
					schemas = {
						kubernetes = {
							"k8s/**/*.yaml",
							"k8s/**/*.yml",
							"kubernetes/**/*.yaml",
							"kubernetes/**/*.yml",
							"manifests/**/*.yaml",
							"manifests/**/*.yml",
							"deploy/**/*.yaml",
							"deploy/**/*.yml",
							"*.k8s.yaml",
							"*.k8s.yml",
						},
					},
				},
			},
		},
	},
}
