-- ================================================================================================
-- TITLE : nvim-treesitter
-- ABOUT : Treesitter parser installer and queries; highlighting and selection are built into nvim.
-- LINKS :
--   > github : https://github.com/nvim-treesitter/nvim-treesitter
-- ================================================================================================

local function has_query(lang, name)
	local ok, query = pcall(vim.treesitter.query.get, lang, name)
	return ok and query ~= nil
end

require("nvim-treesitter").install(require("languages").parsers())

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
	callback = function(args)
		local lang = vim.treesitter.language.get_lang(args.match)
		-- A parser without highlight queries (e.g. left behind by the master branch) would blank the buffer.
		if not lang or not vim.treesitter.language.add(lang) or not has_query(lang, "highlights") then
			return
		end
		vim.treesitter.start(args.buf, lang)
		-- nvim-treesitter's indentexpr returns 0 for every line when a language has no indents query.
		if has_query(lang, "indents") then
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end

		-- Selection uses nvim 0.12's built-in an/in. They are Lua maps, so these need remap.
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, remap = true, desc = desc })
		end
		map("n", "<CR>", "van", "Start treesitter selection")
		map("x", "<CR>", "an", "Grow treesitter selection")
		map("x", "<S-Tab>", "in", "Shrink treesitter selection")
	end,
})
