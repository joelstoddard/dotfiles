-- ================================================================================================
-- TITLE : ash.nvim
-- ABOUT : a minimal, largely monochromatic colorscheme.
-- LINKS :
--   > github : https://github.com/bjarneo/ash.nvim
-- ================================================================================================

require("ash").setup({
	-- ash draws borders in its background colour, which hides float borders and split lines.
	colors = { border = "#626262" },
})
vim.cmd.colorscheme("ash")
