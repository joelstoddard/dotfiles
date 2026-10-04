-- Runs inside a headless start of the real config, after vim.pack.add() has cloned any missing plugin.
-- Exits 0 once plugins, parsers and Mason tools are all installed, or 1 with the step that failed.
local languages = require("languages")
local deadline = vim.uv.now() + 15 * 60 * 1000

local function fail(step, detail)
	io.stderr:write(("bootstrap: %s failed: %s\n"):format(step, detail))
	vim.cmd("cquit 1")
end

local function remaining()
	return math.max(deadline - vim.uv.now(), 1000)
end

-- The config schedules install_missing() at startup, and it can run during the parser step's wait. This hook comes
-- first, so it also catches a notice from that early run.
local notice
local notify = vim.notify
vim.notify = function(msg, level, opts)
	if type(msg) == "string" and msg:find("^Mason could not") then
		notice = msg
	end
	return notify(msg, level, opts)
end

-- A failed clone or a config error at startup shows in :messages. vim.pack.get() never lists a failed clone.
local startup = vim.api.nvim_exec2("messages", { output = true }).output
if startup:find("[Ee]rror") then
	fail("plugins", "startup reported: " .. startup)
end
io.stdout:write("bootstrap: plugins ready\n")

local function read_lock(path)
	return vim.json.decode(table.concat(vim.fn.readfile(path), "\n")).plugins
end

-- vim.pack.get() reports the lockfile's revision, not the checkout's, so ask git.
local function head(path)
	local res = vim.system({ "git", "-C", path, "rev-parse", "HEAD" }, { text = true }):wait()
	return res.code == 0 and vim.trim(res.stdout) or nil
end

local function off_lock(lock)
	local off = {}
	for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
		local want = lock[plugin.spec.name]
		if plugin.active and (not want or head(plugin.path) ~= want.rev) then
			table.insert(off, plugin.spec.name)
		end
	end
	table.sort(off)
	return off
end

local lock_path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
local updating = vim.env.NVIM_TEST_UPDATE == "1"

-- The checkout's file, because vim.pack.add() has already written new plugins into the temporary copy.
local committed = read_lock(vim.env.NVIM_TEST_ROOT .. "/nvim-pack-lock.json")
local unlocked, stray, active_names, active_src = {}, {}, {}, {}
for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
	local name = plugin.spec.name
	if plugin.active then
		active_names[name] = true
		active_src[name] = plugin.spec.src
		if not committed[name] then
			table.insert(unlocked, name)
		end
	elseif not committed[name] then
		table.insert(stray, name)
	end
end
if #unlocked > 0 and not updating then
	fail("sync", "not in nvim-pack-lock.json, run sh tests/run.sh --update: " .. table.concat(unlocked, ", "))
end

-- lock_sync repairs any folder it finds on disk into the lockfile, so a plugin dropped from init.lua would come
-- back via --update unless its leftover install is removed first. The test install is disposable.
if #stray > 0 then
	table.sort(stray)
	vim.pack.del(stray)
	io.stdout:write("bootstrap: removed stray plugins: " .. table.concat(stray, ", ") .. "\n")
end

local orphaned = {}
for name in pairs(committed) do
	if not active_names[name] then
		table.insert(orphaned, name)
	end
end
if #orphaned > 0 then
	table.sort(orphaned)
	fail(
		"sync",
		"in nvim-pack-lock.json but not in lua/plugins/init.lua, delete their entries: " .. table.concat(orphaned, ", ")
	)
end

-- Catch a plugin changed in lua/plugins/init.lua without --update, before the sync below copies it back unnoticed.
-- vim.pack.add() has already rewritten version in the temporary lockfile, but src only changes there during the sync.
if not updating then
	local temp = read_lock(lock_path)
	local outdated = {}
	for name in pairs(active_names) do
		local c = committed[name]
		if c.src ~= active_src[name] or c.version ~= temp[name].version then
			table.insert(outdated, name)
		end
	end
	if #outdated > 0 then
		table.sort(outdated)
		fail(
			"sync",
			"out of date with lua/plugins/init.lua, run sh tests/run.sh --update: " .. table.concat(outdated, ", ")
		)
	end
end

-- vim.pack logs each plugin's error to a file that is deleted on exit, so a sync or update failure folds its tail
-- into the detail shown here.
local function pack_log_tail()
	local path = vim.fn.stdpath("log") .. "/nvim-pack.log"
	local lines = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
	if #lines == 0 then
		return nil
	end
	return table.concat(lines, "\n", math.max(1, #lines - 19))
end

local function sync_detail(ok, err, off)
	local reasons = {}
	if not ok then
		table.insert(reasons, "vim.pack.update failed: " .. tostring(err))
	end
	if #off > 0 then
		table.insert(reasons, "off the lockfile: " .. table.concat(off, ", "))
	end
	local log = pack_log_tail()
	if log then
		table.insert(reasons, "nvim-pack.log (last 20 lines):\n" .. log)
	end
	return table.concat(reasons, "; ")
end

-- vim.pack.add() leaves a plugin that is already on disk at its old revision, so this moves each one to the lockfile.
-- The install already holds every committed revision, so the sync runs offline and retries online only if needed.
local synced, sync_err = pcall(vim.pack.update, nil, { target = "lockfile", force = true, offline = true })
local off = off_lock(read_lock(lock_path))
if synced and #off > 0 then
	synced, sync_err = pcall(vim.pack.update, off, { target = "lockfile", force = true })
	off = off_lock(read_lock(lock_path))
end
if not synced or #off > 0 then
	fail("sync", sync_detail(synced, sync_err, off))
end
io.stdout:write("bootstrap: plugins on the lockfile\n")

if updating then
	local updated, update_err = pcall(vim.pack.update, nil, { force = true })
	local stale = off_lock(read_lock(lock_path))
	if not updated or #stale > 0 then
		fail("update", sync_detail(updated, update_err, stale))
	end
	io.stdout:write("bootstrap: plugins updated\n")
end

-- A second install() stops waiting on the config's startup install after 60 s, so this retries each parser that
-- still fails to load. force is needed because install() counts a language as installed once its queries exist.
local parsers = languages.parsers()
local function missing_parsers()
	-- A failed language.add() keeps failing in this process, even after the parser file appears, until
	-- runtimepath changes.
	vim.o.runtimepath = vim.o.runtimepath
	local missing = {}
	for _, lang in ipairs(parsers) do
		local ok, err = vim.treesitter.language.add(lang)
		if not ok then
			table.insert(missing, { lang = lang, err = err })
		end
	end
	return missing
end

local function parser_names(missing)
	return vim.tbl_map(function(m)
		return m.lang
	end, missing)
end

local ok, done = true, true
local still_missing_parsers = missing_parsers()
for _ = 1, 3 do
	if #still_missing_parsers == 0 then
		break
	end
	ok, done = pcall(function()
		return require("nvim-treesitter")
			.install(parser_names(still_missing_parsers), { force = true })
			:wait(remaining())
	end)
	if not ok then
		break
	end
	still_missing_parsers = missing_parsers()
end
if not ok or #still_missing_parsers > 0 then
	local reason = not ok and tostring(done) .. "; " or not done and "timed out; " or ""
	local detail = table.concat(
		vim.tbl_map(function(m)
			return ("%s (%s)"):format(m.lang, m.err)
		end, still_missing_parsers),
		", "
	)
	fail("parsers", reason .. "missing: " .. detail)
end
io.stdout:write("bootstrap: parsers ready\n")

local registry = require("mason-registry")
local function missing_packages()
	local missing = {}
	for _, name in ipairs(languages.mason_packages()) do
		local pkg = registry.has_package(name) and registry.get_package(name)
		local receipt = pkg and pkg:is_installed() and vim.fs.joinpath(pkg:get_install_path(), "mason-receipt.json")
		if not (receipt and vim.uv.fs_stat(receipt)) then
			table.insert(missing, name)
		end
	end
	return missing
end

vim.wait(remaining(), function()
	return notice ~= nil or #missing_packages() == 0
end, 1000)
-- Mason warns when it cannot refresh a stale registry, even when every package is installed. So the bootstrap
-- fails only when a package is missing.
local still_missing = missing_packages()
if #still_missing > 0 then
	if notice then
		fail("Mason", notice)
	end
	fail("Mason", "still missing after the timeout: " .. table.concat(still_missing, ", "))
end
io.stdout:write("bootstrap: Mason tools ready\n")
vim.cmd("qall!")
