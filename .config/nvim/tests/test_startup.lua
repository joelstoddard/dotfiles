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
	return child.lua([[
		local out = {}
		-- The config's Mason check sets the flag when it ends (lua/languages/init.lua). get_clients() hides servers that
		-- are still starting unless _uninitialized is set.
		local settled = vim.wait(10000, function()
			if not vim.g.languages_install_done then
				return false
			end
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, _uninitialized = true })) do
				if not client.initialized then
					return false
				end
			end
			return true
		end)
		if not settled then
			table.insert(out, "startup work still running after 10 s")
		end
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
	-- vim.wait returns false when the time runs out, so a highlighter that never starts fails the test.
	local active = child.lua([[
		return vim.wait(5000, function()
			return vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil
		end)
	]])
	expect.equality(active, true)
end

return T
