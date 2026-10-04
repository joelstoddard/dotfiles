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

-- vim.diagnostic.jump() only moves the cursor, so show the diagnostic it lands on.
local function show_diagnostic()
	vim.diagnostic.open_float({ scope = "cursor", focus = false })
end

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
	-- The built-in ]d and [d use this too, so they open the float on arrival.
	jump = { on_jump = show_diagnostic },
})

-- Keymaps on attach -----------------------------------------------------------------------------
local function on_attach(event)
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if not client then
		return
	end
	local bufnr = event.buf
	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end

	-- The picker jumps straight to the definition when there is only one.
	map("<leader>gd", function()
		require("fzf-lua").lsp_definitions()
	end, "Go to definition (picker)")
	map("<leader>gD", vim.lsp.buf.definition, "Go to definition")
	map("<leader>gS", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, "Go to definition in a split")
	-- Hover, rename and code actions use nvim's built-in K, grn and gra.

	map("<leader>fd", "<cmd>FzfLua lsp_finder<CR>", "Find definitions and references")
	map("<leader>fr", "<cmd>FzfLua lsp_references<CR>", "Find references")
	map("<leader>ft", "<cmd>FzfLua lsp_typedefs<CR>", "Find type definitions")
	map("<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", "Find symbols in this file")
	map("<leader>fw", "<cmd>FzfLua lsp_workspace_symbols<CR>", "Find symbols in the workspace")
	map("<leader>fi", "<cmd>FzfLua lsp_implementations<CR>", "Find implementations")

	-- Only servers that offer code actions can organise imports.
	if client:supports_method("textDocument/codeAction", bufnr) then
		map("<leader>oi", function()
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
		end, "Organise imports")
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
