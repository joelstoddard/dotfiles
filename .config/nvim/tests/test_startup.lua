-- A clean start shows no problems: nothing in :messages, and no warning or error in mini.notify's history (the
-- config routes vim.notify there).
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

local function problems()
	-- Work the config schedules at startup, such as Mason's registry check, has run by then.
	vim.uv.sleep(2000)
	return child.lua([[
		local out = {}
		local messages = vim.api.nvim_exec2("messages", { output = true }).output
		if messages ~= "" then
			table.insert(out, messages)
		end
		for _, n in ipairs(MiniNotify.get_all()) do
			if n.level == "WARN" or n.level == "ERROR" then
				table.insert(out, n.msg)
			end
		end
		return out
	]])
end

T["shows no problems with no file"] = function()
	child = helpers.new_child()
	expect.equality(problems(), {})
end

-- vim.uv.fs_realpath resolves /var vs /private/var, so a temp path compares equal to itself on both sides.
local function expect_opened(dir, name)
	local got = child.lua_get("vim.api.nvim_buf_get_name(0)")
	expect.equality(vim.uv.fs_realpath(got), vim.uv.fs_realpath(dir .. "/" .. name))
end

T["shows no problems on a file outside git"] = function()
	local dir = helpers.tempdir()
	helpers.write(dir .. "/notes.py", "x = 1\n")
	child = helpers.new_child({ cwd = dir, args = { "notes.py" } })
	expect_opened(dir, "notes.py")
	expect.equality(problems(), {})
end

T["shows no problems on an untracked file"] = function()
	local dir = helpers.git_repo({ ["tracked.txt"] = "a\n" }, { ["untracked.py"] = "y = 2\n" })
	child = helpers.new_child({ cwd = dir, args = { "untracked.py" } })
	expect_opened(dir, "untracked.py")
	expect.equality(problems(), {})
end

T["keeps the checkout out of the test install's config folder"] = function()
	child = helpers.new_child()
	local config = child.lua_get([[vim.uv.fs_realpath(vim.fn.stdpath("config"))]])
	local root = vim.uv.fs_realpath(vim.env.NVIM_TEST_ROOT)
	expect.equality(config == root, false)
end

T["keeps undo files in the instance's own data folder"] = function()
	child = helpers.new_child()
	local undo = child.lua([[
		local expected = vim.fn.stdpath("data") .. "/undodir"
		return { vim.o.undodir == expected, vim.fn.isdirectory(expected) == 1, vim.o.undodir }
	]])
	expect.equality(undo, { true, true, undo[3] })
end

T["starts treesitter on a file outside git"] = function()
	local dir = helpers.tempdir()
	helpers.write(dir .. "/notes.py", "x = 1\n")
	child = helpers.new_child({ cwd = dir, args = { "notes.py" } })
	vim.uv.sleep(500)
	local active = child.lua([[
		return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil
	]])
	expect.equality(active, true)
end

return T
