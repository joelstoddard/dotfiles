-- ================================================================================================
-- TITLE : nvim-tree.lua
-- ABOUT : A file explorer tree for Neovim, written in Lua.
-- LINKS :
--   > github : https://github.com/nvim-tree/nvim-tree.lua
-- ================================================================================================

-- Remove background color from the NvimTree window (ui fix)
vim.cmd([[hi NvimTreeNormal guibg=NONE ctermbg=NONE]])

require("nvim-tree").setup({
	filters = {
		dotfiles = false, -- Show hidden files (dotfiles)
	},
	view = {
		adaptive_size = true,
	},
	renderer = {
		icons = {
			glyphs = {
				-- The same symbols the shell prompt (oh-my-posh) uses for untracked, modified and deleted files.
				git = { untracked = "\u{EA7F}", unstaged = "\u{EB43}", deleted = "\u{EA81}" },
			},
		},
	},
})
