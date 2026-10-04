-- Indent shading (lua/config/indent.lua, #14) and the colorcolumn at each language's line length (#17).
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

T["splits leading whitespace into one band per indent level"] = function()
	local L1, L2, L3, L4 = "IndentLevel1", "IndentLevel2", "IndentLevel3", "IndentLevel4"
	local cases = {
		{ "x", 4, 4, {} },
		{ "    ", 4, 4, {} },
		{ "    x", 4, 4, { { 0, 4, L1 } } },
		{ "        x", 4, 4, { { 0, 4, L1 }, { 4, 8, L2 } } },
		{ "\tx", 4, 4, { { 0, 1, L1 } } },
		-- A tab that spans two levels belongs to the level where it starts.
		{ "\t  x", 2, 4, { { 0, 1, L1 }, { 1, 3, L3 } } },
		-- Groups cycle after four levels.
		{ (" "):rep(20) .. "x", 4, 4, { { 0, 4, L1 }, { 4, 8, L2 }, { 8, 12, L3 }, { 12, 16, L4 }, { 16, 20, L1 } } },
	}
	for _, case in ipairs(cases) do
		local line, width, tabstop, bands = case[1], case[2], case[3], case[4]
		local got = child.lua_get('require("config.indent").bands(...)', { line, width, tabstop })
		expect.equality({ line, width, got }, { line, width, bands })
	end
end

T["shades each level and the colorcolumn in its own grey"] = function()
	local greys = {
		IndentLevel1 = "#161616",
		IndentLevel2 = "#1a1a1a",
		IndentLevel3 = "#1e1e1e",
		IndentLevel4 = "#222222",
		ColorColumn = "#1c1c1c",
	}
	for name, grey in pairs(greys) do
		expect.equality({ name, helpers.hl(child, name).bg }, { name, grey })
	end
end

T["sets the colorcolumn at each language's line length"] = function()
	-- Read from the language modules, so a new language is covered without a change here.
	local expected = child.lua([[
		local out = {}
		for _, file in ipairs(vim.api.nvim_get_runtime_file("lua/languages/*.lua", true)) do
			local name = vim.fn.fnamemodify(file, ":t:r")
			if name ~= "init" then
				local lang = require("languages." .. name)
				for _, ft in ipairs(lang.filetypes or {}) do
					out[ft] = lang.line_length and tostring(lang.line_length) or ""
				end
			end
		end
		return out
	]])
	expect.equality(expected.lua, "120")
	expect.equality(expected.markdown, "")
	-- Only the config's own FileType handler runs, so no language server or parser starts.
	-- A sentinel no language uses catches a filetype whose handler silently didn't run.
	local actual = child.lua(
		[[
		local out = {}
		for ft in pairs(...) do
			vim.wo.colorcolumn = "999"
			vim.api.nvim_exec_autocmds("FileType", { group = "LanguageLineLength", pattern = ft })
			out[ft] = vim.wo.colorcolumn
		end
		return out
	]],
		{ expected }
	)
	expect.equality(actual, expected)
end

T["clears the colorcolumn when a window switches to a file with no limit"] = function()
	local dir = helpers.tempdir()
	helpers.write(dir .. "/a.py", "x = 1\n")
	helpers.write(dir .. "/b.md", "# Notes\n")
	child.cmd("edit " .. dir .. "/a.py")
	expect.equality(child.lua_get("vim.wo.colorcolumn"), "88")
	child.cmd("edit " .. dir .. "/b.md")
	expect.equality(child.lua_get("vim.wo.colorcolumn"), "")
end

return T
