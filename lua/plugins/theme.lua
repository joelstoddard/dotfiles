-- ================================================================================================
-- TITLE : gruvbox.nvim
-- ABOUT : A port of gruvbox community theme to lua with treesitter and semantic highlights support!
-- LINKS :
--   > github : https://github.com/ellisonleao/gruvbox.nvim
-- ================================================================================================

return {
	"ellisonleao/gruvbox.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		vim.cmd("colorscheme gruvbox")
	end,
}
