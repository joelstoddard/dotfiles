-- ================================================================================================
-- TITLE : nvim-sops
-- ABOUT : Encrypt and decrypt sops files in-buffer. Wraps the `sops` CLI; works with any recipient
--         type (age, AWS KMS, GCP, etc.) using metadata embedded in the file. No `.sops.yaml`
--         required for editing.
-- LINKS :
--   > github : https://github.com/prismatic-koi/nvim-sops
-- ================================================================================================

local sops_patterns = {
	-- generic "under a secrets directory" or named secrets.env
	"*/secrets.env",
	"*/secrets/*",

	-- ansible vaults
	"*vault*.yml",
	"*vault*.yaml",

	-- sops-explicit naming
	"*.sops",
	"*.sops.yaml",
	"*.sops.yml",
	"*.sops.json",
	"*.sops.env",
	"*.sops.ini",
	"*.sops.toml",

	-- "encrypted" naming convention
	"*.enc.yaml",
	"*.enc.yml",
	"*.enc.json",
	"*.enc.env",

	-- kubernetes/helm secret manifests and values files
	"*secret*.yaml",
	"*secret*.yml",
	"*secret*.json",
	"*secret*.env",

	-- credentials files (gcp service accounts, aws creds, etc.)
	"*credentials*.json",
	"*credentials*.yaml",
	"*credentials*.yml",

	-- terraform tfvars with secrets
	"secrets.tfvars",
	"*.secret.tfvars",
}

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	group = vim.api.nvim_create_augroup("sops_harden", { clear = true }),
	pattern = sops_patterns,
	callback = function()
		vim.opt_local.undofile = false
	end,
	desc = "Disable persistent undo for sops-encrypted file paths",
})

return {
	"prismatic-koi/nvim-sops",
	event = { "BufReadPost" },
	opts = {},
	keys = {
		{ "<leader>Sd", "<cmd>SopsDecrypt<cr>", desc = "Sops: decrypt buffer" },
		{ "<leader>Se", "<cmd>SopsEncrypt<cr>", desc = "Sops: encrypt buffer" },
	},
}
