-- ================================================================================================
-- TITLE : ash.nvim
-- ABOUT : a minimal, largely monochromatic colorscheme.
-- LINKS :
--   > github : https://github.com/bjarneo/ash.nvim
-- ================================================================================================

require("ash").setup({
	-- ash draws borders and the colorcolumn in its background colour, which hides them.
	colors = { border = "#626262" },
	highlights = { ColorColumn = { bg = "#1c1c1c" } },
})
vim.cmd.colorscheme("ash")
