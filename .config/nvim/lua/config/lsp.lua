-- ================================================================================================
-- TITLE : LSP
-- ABOUT : diagnostics, keymaps on attach, server configs and efm linters/formatters.
-- LINKS :
--   > nvim-lspconfig     : https://github.com/neovim/nvim-lspconfig
--   > efm-langserver     : https://github.com/mattn/efm-langserver
--   > efmls-configs-nvim : https://github.com/creativenull/efmls-configs-nvim
-- ================================================================================================

-- Diagnostics -----------------------------------------------------------------------------------
local diagnostic_signs = {
	Error = "\u{f057} ",
	Warn = "\u{f071} ",
	Hint = "\u{ea61}",
	Info = "\u{f05a}",
}

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
})

-- Keymaps on attach -----------------------------------------------------------------------------
-- vim.diagnostic.jump() only moves the cursor, so show the diagnostic it lands on.
local function show_diagnostic()
	vim.diagnostic.open_float({ scope = "cursor", focus = false })
end

local function on_attach(event)
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if not client then
		return
	end
	local bufnr = event.buf
	local keymap = vim.keymap.set
	local opts = {
		noremap = true, -- prevent recursive mapping
		silent = true, -- don't print the command to the cli
		buffer = bufnr, -- restrict the keymap to the local buffer number
	}

	-- native neovim keymaps
	keymap("n", "<leader>gd", function()
		require("fzf-lua").lsp_definitions()
	end, opts) -- goto definition (picker, or jump when there is one result)
	keymap("n", "<leader>gD", vim.lsp.buf.definition, opts) -- goto definition
	keymap("n", "<leader>gS", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, opts) -- goto definition in split
	keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- Code actions
	keymap("n", "<leader>rn", vim.lsp.buf.rename, opts) -- Rename symbol
	keymap("n", "<leader>D", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, opts) -- Line diagnostics (float)
	keymap("n", "<leader>d", function()
		vim.diagnostic.open_float({ scope = "cursor" })
	end, opts) -- Cursor diagnostics
	keymap("n", "<leader>pd", function()
		vim.diagnostic.jump({ count = -1, on_jump = show_diagnostic })
	end, opts) -- previous diagnostic
	keymap("n", "<leader>nd", function()
		vim.diagnostic.jump({ count = 1, on_jump = show_diagnostic })
	end, opts) -- next diagnostic
	keymap("n", "K", vim.lsp.buf.hover, opts) -- hover documentation

	-- fzf-lua keymaps
	keymap("n", "<leader>fd", "<cmd>FzfLua lsp_finder<CR>", opts) -- LSP Finder (definition + references)
	keymap("n", "<leader>fr", "<cmd>FzfLua lsp_references<CR>", opts) -- Show all references to the symbol under the cursor
	keymap("n", "<leader>ft", "<cmd>FzfLua lsp_typedefs<CR>", opts) -- Jump to the type definition of the symbol under the cursor
	keymap("n", "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", opts) -- List all symbols (functions, classes, etc.) in the current file
	keymap("n", "<leader>fw", "<cmd>FzfLua lsp_workspace_symbols<CR>", opts) -- Search for any symbol across the entire project/workspace
	keymap("n", "<leader>fi", "<cmd>FzfLua lsp_implementations<CR>", opts) -- Go to implementation

	-- Order Imports (if supported by the client LSP)
	if client:supports_method("textDocument/codeAction", bufnr) then
		keymap("n", "<leader>oi", function()
			vim.lsp.buf.code_action({
				context = {
					only = { "source.organizeImports" },
					diagnostics = {},
				},
				apply = true,
				bufnr = bufnr,
			})
			-- format after changing import order
			vim.defer_fn(function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end, 50) -- slight delay to allow for the import order to go first
		end, opts)
	end
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspMappings", {}),
	callback = on_attach,
})

-- Servers ---------------------------------------------------------------------------------------
-- blink.cmp registers its completion capabilities on vim.lsp.config("*"), so no server repeats them.
local languages = require("languages")
local servers = languages.servers()
for name, config in pairs(servers) do
	vim.lsp.config(name, config)
end

-- Linters & formatters (efm) --------------------------------------------------------------------
local efm_languages = languages.efm()
vim.lsp.config("efm", {
	filetypes = vim.tbl_keys(efm_languages),
	init_options = {
		documentFormatting = true,
		documentRangeFormatting = true,
		hover = true,
		documentSymbol = true,
		codeAction = true,
		completion = true,
	},
	settings = { languages = efm_languages },
})

vim.lsp.enable(vim.list_extend(vim.tbl_keys(servers), { "efm" }))
