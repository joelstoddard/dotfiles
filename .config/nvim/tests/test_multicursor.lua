-- Multiple cursors (lua/plugins/multicursor-nvim.lua, #13): Alt+Shift+Up/Down add a cursor per line, <leader>n and
-- <leader>N add one per match, and Esc goes back to one cursor.
local helpers = dofile("tests/helpers.lua")
local new_set, expect = MiniTest.new_set, MiniTest.expect

local child
local T = new_set({
	hooks = {
		pre_case = function()
			child = helpers.new_child()
		end,
		post_case = function()
			child.stop()
		end,
	},
})

local function set_lines(lines)
	child.lua("vim.api.nvim_buf_set_lines(0, 0, -1, false, ...)", { lines })
	child.lua("vim.api.nvim_win_set_cursor(0, { 1, 0 })")
end

local function lines()
	return child.lua_get("vim.api.nvim_buf_get_lines(0, 0, -1, false)")
end

T["adds a cursor on each line below with Alt+Shift+Down"] = function()
	set_lines({ "a", "b", "c", "d" })
	child.type_keys("<M-S-Down>", "<M-S-Down>", "I-<Esc>")
	expect.equality(lines(), { "-a", "-b", "-c", "d" })
end

T["adds a cursor on each line above with Alt+Shift+Up"] = function()
	set_lines({ "a", "b", "c", "d" })
	child.lua("vim.api.nvim_win_set_cursor(0, { 4, 0 })")
	child.type_keys("<M-S-Up>", "I-<Esc>")
	expect.equality(lines(), { "a", "b", "-c", "-d" })
end

T["adds a cursor at the next match with <leader>n"] = function()
	set_lines({ "foo bar foo baz foo" })
	child.type_keys(" n", "ciwqux<Esc>")
	expect.equality(lines(), { "qux bar qux baz foo" })
end

T["adds a cursor at the previous match with <leader>N"] = function()
	set_lines({ "foo bar foo baz foo" })
	child.type_keys(" N", "ciwqux<Esc>")
	expect.equality(lines(), { "qux bar foo baz qux" })
end

T["goes back to one cursor on Esc"] = function()
	set_lines({ "a", "b" })
	child.type_keys("<M-S-Down>")
	expect.equality(child.lua_get('require("multicursor-nvim").hasCursors()'), true)
	child.type_keys("<Esc>")
	expect.equality(child.lua_get('require("multicursor-nvim").hasCursors()'), false)
end

return T
