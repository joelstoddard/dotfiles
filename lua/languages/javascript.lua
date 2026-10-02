-- ================================================================================================
-- TITLE : JavaScript
-- ABOUT : javascript parser, eslint_d and prettierd; ts_ls (typescript.lua) serves JavaScript too.
-- ================================================================================================

-- ESLint 9 warns about every file its config does not cover, such as TypeScript in a JavaScript-only project.
local eslint = require("efmls-configs.linters.eslint_d")
return {
	filetypes = { "javascript", "javascriptreact" },
	line_length = 80, -- prettier's print width
	parsers = { "javascript" },
	lint = { vim.tbl_extend("force", eslint, { lintCommand = eslint.lintCommand .. " --no-warn-ignored" }) },
	format = { "prettier_d" },
	mason = { "eslint_d", "prettierd" },
}
