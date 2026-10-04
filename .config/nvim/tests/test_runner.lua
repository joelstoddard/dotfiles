-- tests/run.sh's arguments. Each case runs a copy of the runner in a fake checkout with a stub nvim, so it never
-- starts the bootstrap or writes the real lockfile.
local helpers = dofile("tests/helpers.lua")
local new_set, expect = MiniTest.new_set, MiniTest.expect

local T = new_set()

-- Returns the runner's exit code and one "<NVIM_TEST_UPDATE>|<NVIM_TEST_FILE>" line for each nvim it started.
local function run(args)
	local checkout, bin = helpers.tempdir(), helpers.tempdir()
	helpers.write(checkout .. "/tests/run.sh", table.concat(vim.fn.readfile("tests/run.sh"), "\n") .. "\n")
	helpers.write(checkout .. "/nvim-pack-lock.json", "{}\n")
	helpers.write(bin .. "/nvim", '#!/bin/sh\necho "$NVIM_TEST_UPDATE|$NVIM_TEST_FILE" >> "$STUB_LOG"\n')
	vim.uv.fs_chmod(bin .. "/nvim", tonumber("755", 8))
	local log = checkout .. "/nvim.log"
	local cmd = vim.list_extend({ "sh", checkout .. "/tests/run.sh" }, args)
	local res = vim.system(cmd, { env = { PATH = bin .. ":" .. vim.env.PATH, STUB_LOG = log } }):wait()
	return { code = res.code, starts = vim.uv.fs_stat(log) and vim.fn.readfile(log) or {} }
end

-- The second start is the suite, which sees both values.
T["runs the whole suite with no arguments"] = function()
	local res = run({})
	expect.equality({ res.code, res.starts[2] }, { 0, "0|" })
end

T["reads --update before a test file"] = function()
	local res = run({ "--update", "tests/test_x.lua" })
	expect.equality({ res.code, res.starts[2] }, { 0, "1|tests/test_x.lua" })
end

T["reads --update after a test file"] = function()
	local res = run({ "tests/test_x.lua", "--update" })
	expect.equality({ res.code, res.starts[2] }, { 0, "1|tests/test_x.lua" })
end

T["rejects a second test file before starting nvim"] = function()
	local res = run({ "tests/test_x.lua", "tests/test_y.lua" })
	expect.equality({ res.code, res.starts }, { 64, {} })
end

T["rejects an unknown option before starting nvim"] = function()
	local res = run({ "--updte" })
	expect.equality({ res.code, res.starts }, { 64, {} })
end

return T
