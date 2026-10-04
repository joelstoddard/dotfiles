-- ================================================================================================
-- TITLE : which-key
-- ABOUT : WhichKey helps you remember your Neovim keymaps, by showing keybindings as you type.
-- LINKS :
--   > github : https://github.com/folke/which-key.nvim
-- ================================================================================================

require("which-key").setup({
	spec = {
		{ "<leader>c", group = "code" },
		{ "<leader>f", group = "find" },
		{ "<leader>g", group = "goto" },
		{ "<leader>h", group = "hunks" },
		{ "<leader>o", group = "imports" },
		{ "<leader>r", group = "config" },
		{ "<leader>S", group = "sops" },
		{ "<leader>w", group = "session" },
		{ "<leader>x", group = "diagnostics" },
	},
})

vim.keymap.set("n", "<leader>?", function()
	require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
