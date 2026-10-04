-- The statusline (lua/plugins/lualine-nvim.lua, #16): plain grey on the editor background, colour only for signals.
local helpers = dofile("tests/helpers.lua")
local new_set, expect = MiniTest.new_set, MiniTest.expect

local child, p, summary
local T = new_set({
	hooks = {
		-- A tracked file with one added and one changed line, two errors and one warning. No language server
		-- attaches to a .txt file, so these diagnostics are the only ones.
		pre_case = function()
			local dir = helpers.git_repo(
				{ ["src/pkg/notes.txt"] = "one\ntwo\nthree\n" },
				{ ["src/pkg/notes.txt"] = "one\nadded\ntwo\nchanged\n" }
			)
			child = helpers.new_child({ cwd = dir, args = { "src/pkg/notes.txt" } })
			p = helpers.palette(child)
			summary = child.lua([[
				vim.wait(10000, function()
					local s = vim.b.minidiff_summary
					return s ~= nil and (s.add or 0) + (s.change or 0) > 0
				end, 100)
				local ns = vim.api.nvim_create_namespace("statusline-test")
				vim.diagnostic.set(ns, 0, {
					{ lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = "first error" },
					{ lnum = 1, col = 0, severity = vim.diagnostic.severity.ERROR, message = "second error" },
					{ lnum = 2, col = 0, severity = vim.diagnostic.severity.WARN, message = "a warning" },
				})
				return vim.b.minidiff_summary
			]])
		end,
		post_case = function()
			child.stop()
		end,
	},
})

local function segment_with(line, needle)
	for _, segment in ipairs(line.segments) do
		if segment.text:find(needle, 1, true) then
			return segment
		end
	end
end

local function expect_plain(line)
	for _, segment in ipairs(line.segments) do
		expect.equality({ segment.text, segment.bg }, { segment.text, p.bg })
	end
end

T["draws every section on the editor background, with the mode in grey"] = function()
	local line = helpers.statusline(child)
	expect_plain(line)
	expect.equality((segment_with(line, "NORMAL") or {}).fg, p.muted)
	child.type_keys("i")
	line = helpers.statusline(child)
	expect_plain(line)
	expect.equality((segment_with(line, "INSERT") or {}).fg, p.muted)
end

T["shows the branch in orange"] = function()
	local line = helpers.statusline(child)
	expect.equality(line.text:find("\u{E0A0}%s*main") ~= nil, true)
	expect.equality((segment_with(line, "main") or {}).fg, p.orange)
end

T["counts changed lines like mini.diff, with the prompt's symbols"] = function()
	expect.equality((summary.add or 0) + (summary.change or 0) > 0, true)
	local line = helpers.statusline(child)
	local marks = {
		{ "\u{EA7F}", summary.add or 0, p.green },
		{ "\u{EB43}", summary.change or 0, p.purple },
		{ "\u{EA81}", summary.delete or 0, p.red },
	}
	for _, mark in ipairs(marks) do
		local glyph, count, colour = mark[1], mark[2], mark[3]
		local segment = segment_with(line, glyph)
		if count > 0 then
			expect.equality({ glyph, segment and tonumber(segment.text:match(glyph .. "%s*(%d+)")) }, { glyph, count })
			expect.equality({ glyph, segment.fg }, { glyph, colour })
		else
			expect.equality({ glyph, segment }, { glyph, nil })
		end
	end
	expect.equality(line.text:match("[+~]%d"), nil)
end

T["counts diagnostics with the sign column's glyphs"] = function()
	local line = helpers.statusline(child)
	for _, mark in ipairs({ { "\u{F057}", 2, p.red }, { "\u{F071}", 1, p.yellow } }) do
		local glyph, count, colour = mark[1], mark[2], mark[3]
		local segment = segment_with(line, glyph)
		expect.equality({ glyph, segment and tonumber(segment.text:match(glyph .. "%s*(%d+)")) }, { glyph, count })
		expect.equality({ glyph, segment.fg }, { glyph, colour })
	end
end

T["shows the relative path and location, without the usual encoding or progress"] = function()
	local text = helpers.statusline(child).text
	expect.equality(text:find("src/pkg/notes.txt", 1, true) ~= nil, true)
	expect.equality(text:find("1:1", 1, true) ~= nil, true)
	expect.equality(text:find("utf-8", 1, true), nil)
	expect.equality(text:find("\u{E712}", 1, true), nil)
	for _, progress in ipairs({ "Top", "Bot", "All", "%d%%" }) do
		expect.equality({ progress, text:match(progress) }, { progress, nil })
	end
end

T["dims an inactive window's statusline"] = function()
	child.cmd("split")
	local current = child.lua_get("vim.api.nvim_get_current_win()")
	local other
	for _, win in ipairs(child.lua_get("vim.api.nvim_list_wins()")) do
		if win ~= current then
			other = win
		end
	end
	local line = helpers.statusline(child, other)
	expect.equality(line.text:find("src/pkg/notes.txt", 1, true) ~= nil, true)
	for _, segment in ipairs(line.segments) do
		if segment.text:find("%S") then
			expect.equality({ segment.text, segment.fg }, { segment.text, p.dim })
		end
	end
end

T["shows an unusual encoding and line ending"] = function()
	child.cmd("set fileformat=dos fileencoding=latin1")
	local text = helpers.statusline(child).text
	expect.equality(text:find("latin1", 1, true) ~= nil, true)
	expect.equality(text:find("\u{E70F}", 1, true) ~= nil, true)
end

return T
