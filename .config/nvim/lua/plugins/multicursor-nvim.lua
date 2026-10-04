-- ================================================================================================
-- TITLE : multicursor.nvim
-- LINKS :
--   > github : https://github.com/jake-stewart/multicursor.nvim
-- ABOUT : Multiple cursors that work with normal vim motions, undo and completion.
-- ================================================================================================

local mc = require("multicursor-nvim")
mc.setup()

-- Shift makes these different keys from Alt+Up/Down, which move lines (mini.move).
vim.keymap.set({ "n", "x" }, "<M-S-Up>", function()
	mc.lineAddCursor(-1)
end, { desc = "Add cursor above" })
vim.keymap.set({ "n", "x" }, "<M-S-Down>", function()
	mc.lineAddCursor(1)
end, { desc = "Add cursor below" })
vim.keymap.set({ "n", "x" }, "<leader>n", function()
	mc.matchAddCursor(1)
end, { desc = "Add cursor at next match" })
vim.keymap.set({ "n", "x" }, "<leader>N", function()
	mc.matchAddCursor(-1)
end, { desc = "Add cursor at previous match" })

-- Layer keys apply only while there are extra cursors, so Esc keeps its usual meaning the rest of the time.
mc.addKeymapLayer(function(layer_set)
	layer_set("n", "<Esc>", mc.clearCursors, { desc = "Clear extra cursors" })
end)
