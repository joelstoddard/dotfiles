-- ================================================================================================
-- TITLE : blink.cmp
-- ABOUT : Completion engine with LSP, path, buffer and snippet sources, plus signature help.
-- LINKS :
--   > github                  : https://github.com/saghen/blink.cmp
--   > friendly-snippets (dep) : https://github.com/rafamadriz/friendly-snippets
-- ================================================================================================

require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<C-Space>"] = { "show", "hide" },
		["<C-e>"] = { "cancel", "fallback" },
		["<CR>"] = { "accept", "fallback" },
		["<C-y>"] = { "accept", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-n>"] = { "select_next", "show" },
		["<C-p>"] = { "select_prev", "show" },
		["<Down>"] = { "select_next", "fallback" },
		["<Up>"] = { "select_prev", "fallback" },
		["<C-b>"] = { "scroll_documentation_up", "fallback" },
		["<C-f>"] = { "scroll_documentation_down", "fallback" },
	},
	completion = {
		-- Nothing is preselected, so <CR> inserts a newline until an item is chosen.
		list = { selection = { preselect = false, auto_insert = true } },
		documentation = { auto_show = true },
	},
	cmdline = { enabled = false }, -- keeps the native wildmenu and its 'wildmode' settings
	signature = { enabled = true },
	sources = { default = { "lsp", "path", "buffer", "snippets" } },
})
