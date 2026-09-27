-- ================================================================================================
-- TITLE : plugins
-- ABOUT : installs every plugin with the built-in vim.pack, then loads each plugin's config file.
-- LINKS :
--   > vim.pack : :help vim.pack
-- ================================================================================================

-- nvim-tree replaces netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- vim.pack has no build step, so parser updates hang off PackChanged. It must exist before
-- vim.pack.add() to see first installs.
vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("PackHooks", { clear = true }),
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name ~= "nvim-treesitter" or (kind ~= "install" and kind ~= "update") then
			return
		end
		if not ev.data.active then
			vim.cmd.packadd("nvim-treesitter")
		end
		require("nvim-treesitter").update()
	end,
})

local function gh(repo)
	return "https://github.com/" .. repo
end

-- One list, so a new machine gets a single install prompt and parallel clones.
vim.pack.add({
	gh("bjarneo/ash.nvim"),
	{ src = gh("nvim-mini/mini.nvim"), version = vim.version.range("*") },
	{ src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
	{ src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") }, -- release tags ship a prebuilt fuzzy matcher
	gh("rafamadriz/friendly-snippets"),
	gh("neovim/nvim-lspconfig"),
	gh("mason-org/mason.nvim"),
	gh("creativenull/efmls-configs-nvim"),
	gh("b0o/schemastore.nvim"),
	gh("ibhagwan/fzf-lua"),
	gh("nvim-tree/nvim-tree.lua"),
	gh("nvim-lualine/lualine.nvim"),
	gh("folke/trouble.nvim"),
	gh("folke/which-key.nvim"),
	gh("folke/zen-mode.nvim"),
	gh("uga-rosa/ccc.nvim"),
	gh("prismatic-koi/nvim-sops"),
	gh("christoomey/vim-tmux-navigator"),
})

-- Order matters: the colorscheme first, then mini.nvim's devicons mock before any plugin that draws icons.
require("plugins.theme")
require("plugins.mini-nvim")
require("plugins.nvim-treesitter")
require("plugins.blink-cmp")
require("plugins.mason-nvim")
require("plugins.fzf-lua")
require("plugins.nvim-tree")
require("plugins.lualine-nvim")
require("plugins.trouble-nvim")
require("plugins.which-key")
require("plugins.zen-mode")
require("plugins.ccc-nvim")
require("plugins.nvim-sops")
