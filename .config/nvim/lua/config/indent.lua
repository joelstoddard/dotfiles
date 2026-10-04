-- ================================================================================================
-- TITLE : indent shading
-- ABOUT : shades each indent level's leading whitespace in its own grey, like VS Code's indent-rainbow.
-- ================================================================================================

local M = {}

local ns = vim.api.nvim_create_namespace("IndentShading")
local groups = { "IndentLevel1", "IndentLevel2", "IndentLevel3", "IndentLevel4" }

--- Splits a line's leading whitespace into one band per indent level.
--- width is the indent width in display columns, tabstop the width of a tab.
--- Returns { { start_col, end_col, group }, ... } in byte columns, end exclusive; empty when the line has no
--- indentation or holds only whitespace. A tab that spans two levels belongs to the level where it starts.
function M.bands(line, width, tabstop)
	local indent = line:match("^[ \t]*")
	if #indent == 0 or #indent == #line then
		return {}
	end
	local bands, levels, vcol = {}, {}, 0
	for i = 1, #indent do
		local level = math.floor(vcol / width)
		if levels[#bands] == level then
			bands[#bands][2] = i
		else
			table.insert(bands, { i - 1, i, groups[level % #groups + 1] })
			levels[#bands] = level
		end
		vcol = vcol + (indent:sub(i, i) == "\t" and tabstop - vcol % tabstop or 1)
	end
	return bands
end

-- Decorations are drawn per redraw for the visible lines only, so nothing is stored or kept in sync on edits.
vim.api.nvim_set_decoration_provider(ns, {
	on_win = function(_, _, buf)
		return vim.bo[buf].buftype == ""
	end,
	on_line = function(_, _, buf, row)
		local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
		local width = vim.bo[buf].shiftwidth
		if width == 0 then
			width = vim.bo[buf].tabstop
		end
		for _, band in ipairs(line and M.bands(line, width, vim.bo[buf].tabstop) or {}) do
			vim.api.nvim_buf_set_extmark(
				buf,
				ns,
				row,
				band[1],
				{ end_col = band[2], hl_group = band[3], ephemeral = true }
			)
		end
	end,
})

return M
