-- ================================================================================================
-- TITLE : floating terminal
-- ABOUT : <leader>t toggles a centred floating shell; the terminal buffer survives between toggles.
-- LINKS :
--   > nvim-lite : https://github.com/radleylewis/nvim-lite
-- ================================================================================================

local group = vim.api.nvim_create_augroup("FloatingTerminal", { clear = true })

local state = { buf = nil, win = nil }

-- Only the floating terminal is deleted on a clean exit, so `:terminal <cmd>` output stays readable.
vim.api.nvim_create_autocmd("TermClose", {
	group = group,
	callback = function(args)
		if args.buf == state.buf and vim.v.event.status == 0 then
			pcall(vim.api.nvim_buf_delete, args.buf, {})
		end
	end,
})

vim.api.nvim_create_autocmd("TermOpen", {
	group = group,
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
	end,
})

local function close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, false)
	end
	state.win = nil
end

local function toggle()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		close()
		return
	end
	if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
		state.buf = vim.api.nvim_create_buf(false, true)
		vim.bo[state.buf].bufhidden = "hide"
	end
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
	})
	if vim.bo[state.buf].buftype ~= "terminal" then
		vim.fn.jobstart(vim.o.shell, { term = true })
		-- Buffer-local so terminal pickers such as fzf-lua keep their own <Esc>.
		vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = state.buf, desc = "Terminal normal mode" })
		vim.keymap.set("t", "<C-q>", close, { buffer = state.buf, desc = "Close floating terminal" })
	end
	vim.cmd.startinsert()
end

vim.keymap.set("n", "<leader>t", toggle, { desc = "Toggle floating terminal" })
