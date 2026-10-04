-- ================================================================================================
-- TITLE : ash.nvim
-- ABOUT : a minimal, largely monochromatic colorscheme, with colour kept for diagnostics and git changes.
-- LINKS :
--   > github : https://github.com/bjarneo/ash.nvim
-- ================================================================================================

-- Colour comes from the dotfiles ash-plus palette (theme/palette.yaml) and git's color.diff, so nvim matches the
-- terminal, tmux and git. The statusline (lualine-nvim.lua) uses this palette too.
local c = {
	bg = "#121212",
	muted = "#8a8a8a",
	dim = "#626262",
	orange = "#F79625",
	red = "#AC4242",
	yellow = "#FFDE57",
	green = "#90A959",
	purple = "#AA759F",
}

local highlights = {
	ColorColumn = { bg = "#1c1c1c" },
	-- Indent shading (config/indent.lua): one grey per level, lighter with depth, cycling after four.
	IndentLevel1 = { bg = "#161616" },
	IndentLevel2 = { bg = "#1a1a1a" },
	IndentLevel3 = { bg = "#1e1e1e" },
	IndentLevel4 = { bg = "#222222" },

	-- Git changes use git's color.diff: new, old, and its moved colour for changed lines.
	Added = { fg = c.green },
	Changed = { fg = c.purple },
	Removed = { fg = c.red },
	MiniDiffSignAdd = { fg = c.green },
	MiniDiffSignChange = { fg = c.purple },
	MiniDiffSignDelete = { fg = c.red },
	MiniDiffOverAdd = { fg = c.green, bg = c.bg },
	MiniDiffOverChange = { fg = c.purple, bg = c.bg },
	MiniDiffOverDelete = { fg = c.red, bg = c.bg },
	NvimTreeGitNew = { fg = c.green },
	NvimTreeGitStaged = { fg = c.green },
	NvimTreeGitDirty = { fg = c.purple },
	NvimTreeGitRenamed = { fg = c.purple },
	NvimTreeGitDeleted = { fg = c.red },

	-- mini.icons links these to the diagnostic groups, so they keep their earlier greys and icons stay colourless.
	MiniIconsOrange = { fg = "#9e9e9e" },
	MiniIconsYellow = { fg = "#9e9e9e" },
	MiniIconsRed = { fg = "#8a8a8a" },
}

-- Only problems draw the eye: errors and warnings take colour, info and hints keep ash's grey.
for severity, color in pairs({ Error = c.red, Warn = c.yellow }) do
	highlights["Diagnostic" .. severity] = { fg = color }
	highlights["DiagnosticSign" .. severity] = { fg = color, bg = c.bg }
	highlights["DiagnosticFloating" .. severity] = { fg = color, bg = c.bg }
	highlights["DiagnosticVirtualText" .. severity] = { fg = color, bg = c.bg }
	highlights["DiagnosticUnderline" .. severity] = { undercurl = true, sp = color }
end

require("ash").setup({
	-- ash draws borders and the colorcolumn in its background colour, which hides them.
	colors = { border = "#626262" },
	highlights = highlights,
})
vim.cmd.colorscheme("ash")

return c
