-- Helpers shared by the test files: a child nvim on this checkout's config, git test repos, colours and the
-- statusline. Load with dofile("tests/helpers.lua"); the suite runs from the repo root.
local M = {}

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local site = vim.fn.stdpath("data") .. "/site"

function M.tempdir()
	local dir = vim.fn.tempname()
	vim.fn.mkdir(dir, "p")
	return dir
end

function M.write(path, content)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	local file = assert(io.open(path, "w"))
	file:write(content)
	file:close()
end

function M.git_repo(files, edits)
	local dir = M.tempdir()
	local function git(...)
		local res = vim.system({ "git", "-C", dir, ... }, { text = true }):wait()
		assert(res.code == 0, ("git %s: %s"):format(table.concat({ ... }, " "), res.stderr))
	end
	git("init", "-q", "-b", "main")
	for path, content in pairs(files) do
		M.write(dir .. "/" .. path, content)
	end
	git("add", "-A")
	-- A throwaway identity and a disabled hooks path keep the user's git setup, including any global hooks, out of
	-- test repos.
	git(
		"-c",
		"commit.gpgsign=false",
		"-c",
		"user.name=test",
		"-c",
		"user.email=test@example.invalid",
		"-c",
		"core.hooksPath=/dev/null",
		"commit",
		"-q",
		"-m",
		"baseline"
	)
	for path, content in pairs(edits or {}) do
		if content == false then
			assert(os.remove(dir .. "/" .. path))
		else
			M.write(dir .. "/" .. path, content)
		end
	end
	return dir
end

function M.new_child(opts)
	opts = opts or {}
	local child = MiniTest.new_child_neovim()
	local start_dir = opts.cwd or M.tempdir()
	-- mini.test always passes --clean, which removes the config folder and the data site folder from rtp and
	-- packpath. This adds them back, so the child loads the plugins, parsers and queries.
	local args = {
		"--cmd",
		"cd " .. vim.fn.fnameescape(start_dir),
		"--cmd",
		("set rtp^=%s,%s packpath^=%s"):format(
			vim.fn.fnameescape(root),
			vim.fn.fnameescape(site),
			vim.fn.fnameescape(site)
		),
		"-u",
		root .. "/init.lua",
	}
	-- nvim resolves a relative file argument against its real start folder before the cd above runs, so it is made
	-- absolute here. Only paths that exist are joined, because a flag's value such as "set ft=python" is not a file.
	for _, arg in ipairs(opts.args or {}) do
		if arg:sub(1, 1) ~= "-" and arg:sub(1, 1) ~= "+" and arg:sub(1, 1) ~= "/" then
			local joined = vim.fs.joinpath(start_dir, arg)
			if vim.uv.fs_stat(joined) then
				arg = joined
			end
		end
		table.insert(args, arg)
	end
	child.start(args)
	return child
end

local PALETTE_KEYS = { "bg", "muted", "dim", "orange", "red", "yellow", "green", "purple" }

function M.palette(child)
	local out = child.lua([[
		local out = {}
		for name, value in pairs(require("plugins.theme")) do
			out[name] = value:lower()
		end
		return out
	]])
	for _, key in ipairs(PALETTE_KEYS) do
		assert(out[key] ~= nil, "palette() is missing key: " .. key)
	end
	return out
end

function M.hl(child, group)
	return child.lua(
		[[
		local h = vim.api.nvim_get_hl(0, { name = ..., link = false })
		local function hex(n)
			return n and ("#%06x"):format(n) or nil
		end
		return { fg = hex(h.fg), bg = hex(h.bg), sp = hex(h.sp), undercurl = h.undercurl == true }
	]],
		{ group }
	)
end

function M.is_grey(hex)
	local r, g, b = (type(hex) == "string" and hex or ""):match("^#(%x%x)(%x%x)(%x%x)$")
	return r ~= nil and r == g and g == b
end

function M.hl_at(child, buf, row, col)
	return child.lua(
		[[
		-- Lua keeps only the first value of ... when it is not the last argument, so the arguments are unpacked first.
		local buf, row, col = ...
		local groups = {}
		local pos = vim.inspect_pos(buf, row, col, { extmarks = true, syntax = false, treesitter = false, semantic_tokens = false })
		for _, mark in ipairs(pos.extmarks) do
			if mark.opts.hl_group then
				table.insert(groups, mark.opts.hl_group)
			end
		end
		return groups
	]],
		{ buf, row, col }
	)
end

function M.statusline(child, winid)
	return child.lua(
		[[
		local winid = ... or vim.api.nvim_get_current_win()
		-- lualine writes each window's rendered statusline into that window's option when it refreshes.
		require("lualine").refresh({ force = true, scope = "all", place = { "statusline" } })
		local str = vim.wo[winid].statusline
		local res = vim.api.nvim_eval_statusline(str ~= "" and str or vim.o.statusline, { winid = winid, highlights = true })
		local function hex(n)
			return n and ("#%06x"):format(n) or nil
		end
		local segments = {}
		for i, h in ipairs(res.highlights) do
			local fg, bg
			for j = #h.groups, 1, -1 do
				local group = vim.api.nvim_get_hl(0, { name = h.groups[j], link = false })
				fg, bg = fg or hex(group.fg), bg or hex(group.bg)
			end
			local stop = res.highlights[i + 1] and res.highlights[i + 1].start or #res.str
			table.insert(segments, { text = res.str:sub(h.start + 1, stop), fg = fg, bg = bg })
		end
		return { text = res.str, segments = segments }
	]],
		{ winid }
	)
end

return M
