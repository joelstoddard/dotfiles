-- Keymaps (#18): nvim's built-in keys do the work where they exist, and every LSP keymap says what it does.
local helpers = dofile("tests/helpers.lua")
local new_set, expect = MiniTest.new_set, MiniTest.expect

local child
local T = new_set({
	hooks = {
		post_case = function()
			child.stop()
		end,
	},
})

-- The text of every floating window, so a test can find the diagnostic float among others such as mini.notify's.
local function float_text()
	return child.lua([[
		local out = {}
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_config(win).relative ~= "" then
				local buf = vim.api.nvim_win_get_buf(win)
				table.insert(out, table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
			end
		end
		return table.concat(out, "\n")
	]])
end

T["opens the diagnostic float when ]d and [d land"] = function()
	child = helpers.new_child()
	child.lua([[
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two", "three" })
		local ns = vim.api.nvim_create_namespace("keymaps-test")
		vim.diagnostic.set(ns, 0, { { lnum = 1, col = 0, severity = vim.diagnostic.severity.WARN, message = "on two" } })
	]])
	child.type_keys("]d")
	expect.equality(child.lua_get("vim.fn.line('.')"), 2)
	expect.equality(float_text():find("on two", 1, true) ~= nil, true)
	-- Moving the cursor closes the float, so the second jump must open a new one.
	child.type_keys("G")
	expect.equality(float_text():find("on two", 1, true), nil)
	child.type_keys("[d")
	expect.equality(child.lua_get("vim.fn.line('.')"), 2)
	expect.equality(float_text():find("on two", 1, true) ~= nil, true)
end

-- Opens a Lua file in a git repo and waits until the config's LSP keymaps exist, since they are set per buffer when
-- a server attaches.
local function open_lua_with_server()
	local dir = helpers.git_repo({ ["init.lua"] = "local x = 1\nreturn x\n" })
	child = helpers.new_child({ cwd = dir, args = { "init.lua" } })
	local attached = child.lua([[
		return vim.wait(20000, function()
			return vim.fn.maparg("<leader>gd", "n", false, true).buffer == 1
		end, 100)
	]])
	expect.equality(attached, true)
end

T["describes every keymap set for an LSP buffer"] = function()
	open_lua_with_server()
	local undescribed = child.lua([[
		local out = {}
		for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do
			if (map.desc or "") == "" then
				table.insert(out, map.lhs)
			end
		end
		table.sort(out)
		return out
	]])
	expect.equality(undescribed, {})
end

T["opens hover on K in an LSP buffer"] = function()
	open_lua_with_server()
	local hover = child.lua([[
		local map = vim.fn.maparg("K", "n", false, true)
		return map.callback == vim.lsp.buf.hover or (map.desc or ""):find("hover") ~= nil
	]])
	expect.equality(hover, true)
end

return T
