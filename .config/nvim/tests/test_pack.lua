-- :PackSync (lua/plugins/init.lua, #19): moves plugins to the committed lockfile, never to newer versions.
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

T["moves plugins to the lockfile, with vim.pack's confirmation"] = function()
	child = helpers.new_child()
	-- A stub records the call, so the test needs no network and opens no confirmation buffer.
	local call = child.lua([[
		local seen
		vim.pack.update = function(names, opts)
			seen = { all = names == nil, opts = opts }
		end
		vim.cmd("PackSync")
		return seen
	]])
	expect.equality(call, { all = true, opts = { target = "lockfile" } })
end

return T
