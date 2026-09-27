-- ================================================================================================
-- TITLE : Terraform
-- ABOUT : terraform and hcl parsers, terraformls (validates and formats).
-- ================================================================================================

return {
	filetypes = { "terraform", "terraform-vars" },
	parsers = { "terraform", "hcl" },
	servers = { terraformls = {} },
	format_with = "terraformls",
	mason = { "terraform-ls" },
}
