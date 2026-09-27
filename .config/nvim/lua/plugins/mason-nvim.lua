-- ================================================================================================
-- TITLE : mason.nvim
-- ABOUT : installer and manager for LSP servers, linters and formatters.
-- LINKS :
--   > github : https://github.com/mason-org/mason.nvim
-- ================================================================================================

require("mason").setup({})
-- Scheduled so loading Mason's registry stays out of startup.
vim.schedule(function()
	require("languages").install_missing(require("mason-registry"))
end)
