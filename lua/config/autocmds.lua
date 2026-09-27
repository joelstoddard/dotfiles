-- ================================================================================================
-- TITLE : auto-commands
-- ABOUT : automatically run code on defined events (e.g. save, yank)
-- ================================================================================================

-- Restore last cursor position when reopening a file
local last_cursor_group = vim.api.nvim_create_augroup("LastCursorGroup", {})
vim.api.nvim_create_autocmd("BufReadPost", {
	group = last_cursor_group,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Highlight the yanked text for 200ms
local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
	group = highlight_yank_group,
	pattern = "*",
	callback = function()
		vim.hl.on_yank({
			higroup = "IncSearch",
			timeout = 200,
		})
	end,
})

-- Wrap long lines at word boundaries in markdown files
local markdown_wrap_group = vim.api.nvim_create_augroup("MarkdownWrap", {})
vim.api.nvim_create_autocmd("FileType", {
	group = markdown_wrap_group,
	pattern = "markdown",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
	end,
})

-- Format on save with the language's formatter (efm or its server). Synchronous, so edits land before the write.
local lsp_fmt_group = vim.api.nvim_create_augroup("FormatOnSaveGroup", {})
vim.api.nvim_create_autocmd("BufWritePre", {
	group = lsp_fmt_group,
	callback = function(args)
		local bo = vim.bo[args.buf]
		if bo.buftype ~= "" or not bo.modifiable or vim.api.nvim_buf_get_name(args.buf) == "" then
			return
		end
		local client = require("languages").formatter(bo.filetype)
		if not client or vim.tbl_isempty(vim.lsp.get_clients({ bufnr = args.buf, name = client })) then
			return
		end
		pcall(vim.lsp.buf.format, { bufnr = args.buf, name = client, timeout_ms = 2000 })
	end,
})
