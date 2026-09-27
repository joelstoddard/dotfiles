-- ================================================================================================
-- TITLE : Ansible
-- ABOUT : detects playbooks and roles as yaml.ansible for ansiblels, which runs ansible-lint itself.
-- ================================================================================================

local ansible = "yaml.ansible"

return {
	register = { yaml = { ansible } },
	servers = { ansiblels = {} },
	mason = { "ansible-language-server", "ansible-lint" },
	detect = {
		pattern = {
			[".*/playbooks/.*%.ya?ml"] = ansible,
			[".*/roles/[^/]+/tasks/.*%.ya?ml"] = ansible,
			[".*/roles/[^/]+/handlers/.*%.ya?ml"] = ansible,
			[".*/group_vars/.+"] = ansible,
			[".*/host_vars/.+"] = ansible,
			[".*/site%.ya?ml"] = ansible,
			[".*/playbook[^/]*%.ya?ml"] = ansible,
		},
	},
}
