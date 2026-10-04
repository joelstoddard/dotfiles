-- ================================================================================================
-- TITLE : languages
-- ABOUT : the languages this config supports, one file each, and the views other modules read.
-- ================================================================================================

local names = {
	"bash",
	"zsh",
	"html",
	"css",
	"javascript",
	"typescript",
	"json",
	"lua",
	"markdown",
	"yaml",
	"kubernetes",
	"ansible",
	"compose",
	"helm",
	"terraform",
	"python",
	"docker",
	"go",
	"sql",
}

local M = {}

local loaded
local function all()
	if not loaded then
		loaded = {}
		for _, name in ipairs(names) do
			table.insert(loaded, require("languages." .. name))
		end
	end
	return loaded
end

local function collect(field)
	local seen, list = {}, {}
	for _, lang in ipairs(all()) do
		for _, item in ipairs(lang[field] or {}) do
			if not seen[item] then
				seen[item] = true
				table.insert(list, item)
			end
		end
	end
	return list
end

local function tool(kind, entry)
	return type(entry) == "string" and require("efmls-configs." .. kind .. "." .. entry) or entry
end

--- Filetype rules and parser aliases; call once from init.lua after plugins are added.
function M.setup()
	local line_lengths = {}
	for _, lang in ipairs(all()) do
		if lang.detect then
			vim.filetype.add(lang.detect)
		end
		for parser, filetypes in pairs(lang.register or {}) do
			vim.treesitter.language.register(parser, filetypes)
		end
		for _, ft in ipairs(lang.line_length and lang.filetypes or {}) do
			line_lengths[ft] = lang.line_length
		end
	end
	-- colorcolumn is window-local and survives a buffer switch, so every filetype sets it, empty when it has no limit.
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("LanguageLineLength", { clear = true }),
		callback = function(args)
			vim.opt_local.colorcolumn = line_lengths[args.match] and tostring(line_lengths[args.match]) or ""
		end,
	})
end

function M.parsers()
	return collect("parsers")
end

function M.mason_packages()
	local packages = collect("mason")
	table.insert(packages, "efm")
	return packages
end

--- Server configs merged across files, so one language can extend another's server.
function M.servers()
	local servers = {}
	for _, lang in ipairs(all()) do
		servers = vim.tbl_deep_extend("force", servers, lang.servers or {})
	end
	return servers
end

--- efm's languages table: linters then formatters for each filetype that has any.
function M.efm()
	local languages = {}
	for _, lang in ipairs(all()) do
		local tools = {}
		for _, entry in ipairs(lang.lint or {}) do
			-- efm otherwise lints only after the first change. A copy keeps the shared efmls-configs table intact.
			table.insert(tools, vim.tbl_extend("force", tool("linters", entry), { lintAfterOpen = true }))
		end
		for _, entry in ipairs(lang.format or {}) do
			table.insert(tools, tool("formatters", entry))
		end
		if #tools > 0 then
			for _, ft in ipairs(lang.filetypes or {}) do
				languages[ft] = tools
			end
		end
	end
	return languages
end

--- The LSP client that formats a filetype: efm when efm has a formatter for it, else the server named in
--- format_with, else nil.
function M.formatter(filetype)
	for _, lang in ipairs(all()) do
		if vim.list_contains(lang.filetypes or {}, filetype) then
			if lang.format and #lang.format > 0 then
				return "efm"
			end
			return lang.format_with
		end
	end
end

-- Mason counts any package directory as installed. An interrupted install leaves a directory without a receipt,
-- which Mason never retries.
local function half_built(pkg)
	return pkg:is_installed() and vim.uv.fs_stat(vim.fs.joinpath(pkg:get_install_path(), "mason-receipt.json")) == nil
end

--- Installs missing Mason packages in the background and reports failures in one warning.
function M.install_missing(registry)
	-- Mason can run this callback off the main loop (e.g. after a failed refresh).
	registry.refresh(vim.schedule_wrap(function(refreshed)
		-- A failed refresh leaves an empty registry, which would list every package as unknown.
		if not refreshed then
			vim.notify(
				"Mason could not refresh its registry; missing packages will install on a later start.",
				vim.log.levels.WARN
			)
			return
		end
		local pending, failed, scanning, reported = 0, {}, true, false
		-- Installs can finish before the loop ends, so report only once the loop is done and nothing is pending.
		local function report()
			if scanning or reported or pending > 0 or #failed == 0 then
				return
			end
			reported = true
			vim.schedule(function()
				vim.notify("Mason could not install: " .. table.concat(failed, ", "), vim.log.levels.WARN)
			end)
		end
		for _, name in ipairs(M.mason_packages()) do
			if not registry.has_package(name) then
				table.insert(failed, name .. " (unknown)")
			else
				local pkg = registry.get_package(name)
				local force = half_built(pkg)
				if (force or not pkg:is_installed()) and not pkg:is_installing() then
					pending = pending + 1
					pkg:install({ force = force }, function(success)
						pending = pending - 1
						if not success then
							table.insert(failed, name)
						end
						report()
					end)
				end
			end
		end
		scanning = false
		report()
	end))
end

return M
