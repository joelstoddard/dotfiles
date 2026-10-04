-- The theme (lua/plugins/theme.lua, #15): colour only for problems and git changes; names and icons stay grey.
local helpers = dofile("tests/helpers.lua")
local new_set, expect = MiniTest.new_set, MiniTest.expect

local child, p
local T = new_set({
	hooks = {
		pre_case = function()
			child = helpers.new_child()
			p = helpers.palette(child)
		end,
		post_case = function()
			child.stop()
		end,
	},
})

-- Each expectation carries the group name, so a failure says which group is wrong.
local function expect_fg(name, colour)
	expect.equality({ name, helpers.hl(child, name).fg }, { name, colour })
end

local function expect_grey(name, hex)
	expect.equality({ name, hex, helpers.is_grey(hex) }, { name, hex, true })
end

T["colours errors red and warnings yellow"] = function()
	for severity, colour in pairs({ Error = p.red, Warn = p.yellow }) do
		expect_fg("Diagnostic" .. severity, colour)
		for _, kind in ipairs({ "Sign", "Floating", "VirtualText" }) do
			local name = "Diagnostic" .. kind .. severity
			local h = helpers.hl(child, name)
			expect.equality({ name, h.fg, h.bg }, { name, colour, p.bg })
		end
		local name = "DiagnosticUnderline" .. severity
		local h = helpers.hl(child, name)
		expect.equality({ name, h.undercurl, h.sp }, { name, true, colour })
	end
end

T["keeps info and hints grey"] = function()
	for _, severity in ipairs({ "Info", "Hint" }) do
		for _, kind in ipairs({ "", "Sign", "Floating", "VirtualText" }) do
			local name = "Diagnostic" .. kind .. severity
			expect_grey(name, helpers.hl(child, name).fg)
		end
	end
end

T["uses git's diff colours for changes"] = function()
	local groups = {
		green = { "Added", "MiniDiffSignAdd", "NvimTreeGitNew", "NvimTreeGitStaged" },
		purple = { "Changed", "MiniDiffSignChange", "NvimTreeGitDirty", "NvimTreeGitRenamed" },
		red = { "Removed", "MiniDiffSignDelete", "NvimTreeGitDeleted" },
	}
	for colour, names in pairs(groups) do
		for _, name in ipairs(names) do
			expect_fg(name, p[colour])
		end
	end
	for name, colour in pairs({ MiniDiffOverAdd = p.green, MiniDiffOverChange = p.purple, MiniDiffOverDelete = p.red }) do
		local h = helpers.hl(child, name)
		expect.equality({ name, h.fg, h.bg }, { name, colour, p.bg })
	end
end

T["keeps folders, error messages and nvim-tree's git names grey"] = function()
	local names = child.lua([[
		local out = { "Directory", "ErrorMsg" }
		for name in pairs(vim.api.nvim_get_hl(0, {})) do
			if name:match("^NvimTreeGitFile.*HL$") or name:match("^NvimTreeGitFolder.*HL$") then
				table.insert(out, name)
			end
		end
		return out
	]])
	-- Directory and ErrorMsg, plus at least one nvim-tree group, or the nvim-tree part checks nothing.
	expect.equality(#names > 2, true)
	for _, name in ipairs(names) do
		expect_grey(name, helpers.hl(child, name).fg)
	end
end

T["keeps icons grey"] = function()
	local icons = {
		{ "file", "init.lua" },
		{ "file", "app.py" },
		{ "file", "notes.txt" },
		{ "file", "README.md" },
		{ "file", "Dockerfile" },
		{ "extension", "yaml" },
		{ "filetype", "terraform" },
	}
	for _, icon in ipairs(icons) do
		local group = child.lua_get("(select(2, MiniIcons.get(...)))", icon)
		expect_grey(icon[2] .. " (" .. group .. ")", helpers.hl(child, group).fg)
	end
end

T["gives compose, helm and kubernetes files their own glyphs, in grey"] = function()
	local docker, helm, kubernetes = "\u{F0868}", "\u{F0833}", "\u{F10FE}"
	local icons = {
		{ "file", "docker-compose.yml", docker },
		{ "file", "docker-compose.yaml", docker },
		{ "file", "compose.yml", docker },
		{ "file", "compose.yaml", docker },
		{ "filetype", "yaml.docker-compose", docker },
		{ "file", "Chart.yaml", helm },
		{ "filetype", "yaml.helm-values", helm },
		{ "extension", "k8s.yaml", kubernetes },
		{ "extension", "k8s.yml", kubernetes },
		{ "filetype", "yaml.kubernetes", kubernetes },
	}
	for _, icon in ipairs(icons) do
		local got = child.lua("return { MiniIcons.get(...) }", { icon[1], icon[2] })
		expect.equality({ icon[2], got[1] }, { icon[2], icon[3] })
		expect_grey(icon[2], helpers.hl(child, got[2]).fg)
	end
end

T["marks git changes in nvim-tree with the prompt's symbols"] = function()
	child.stop()
	local dir = helpers.git_repo(
		{ ["app.py"] = "x = 1\n", ["sub/old.txt"] = "old\n" },
		{ ["app.py"] = "x = 2\n", ["sub/old.txt"] = false, ["new.txt"] = "new\n" }
	)
	child = helpers.new_child({ cwd = dir })
	p = helpers.palette(child)
	child.cmd("NvimTreeOpen")
	local marks = { ["app.py"] = "\u{EB43}", ["new.txt"] = "\u{EA7F}", sub = "\u{EA81}" }
	-- nvim-tree reads git status in the background, so wait until every mark is drawn.
	local tree = child.lua(
		[[
		local marks = ...
		local buf = vim.api.nvim_get_current_buf()
		local function locate()
			local rows, lines = {}, vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			for name, glyph in pairs(marks) do
				for row = 2, #lines do
					local line = lines[row]
					if line:match("%s" .. vim.pesc(name) .. "%s*$") then
						local mark = line:find(glyph, 1, true)
						rows[name] = { row = row - 1, mark = mark and mark - 1, icon = line:find("%S") - 1 }
					end
				end
			end
			return rows
		end
		local rows = {}
		vim.wait(10000, function()
			rows = locate()
			for name in pairs(marks) do
				if not (rows[name] and rows[name].mark) then
					return false
				end
			end
			return true
		end, 100)
		return { buf = buf, rows = rows, lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false) }
	]],
		{ marks }
	)
	local function fgs(row, col)
		return vim.tbl_map(function(group)
			return helpers.hl(child, group).fg
		end, helpers.hl_at(child, tree.buf, row, col))
	end
	for name, colour in pairs({ ["app.py"] = p.purple, ["new.txt"] = p.green, sub = p.red }) do
		local row = tree.rows[name]
		expect.equality({ name, row ~= nil and row.mark ~= nil, tree.lines }, { name, true, tree.lines })
		expect.equality({ name, vim.tbl_contains(fgs(row.row, row.mark), colour) }, { name, true })
	end
	-- Only files: folder icons are not part of this config's choices.
	for _, name in ipairs({ "app.py", "new.txt" }) do
		local icon = fgs(tree.rows[name].row, tree.rows[name].icon)
		expect.equality({ name, #icon > 0 and vim.iter(icon):all(helpers.is_grey) }, { name, true })
	end
end

return T
