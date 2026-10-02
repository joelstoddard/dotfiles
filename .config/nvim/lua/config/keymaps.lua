-- ================================================================================================
-- TITLE: NeoVim keymaps
-- ABOUT: sets some quality-of-life keymaps
-- ================================================================================================

-- Leader keys first, so every mapping below and in plugins sees them
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Splitting (resize with the built-in <C-w>+, <C-w>-, <C-w>< and <C-w>>)
vim.keymap.set("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split window horizontally" })

-- Word jumps that stop at punctuation. macOS keeps Ctrl+Arrow for switching Spaces, so it uses Option+Arrow.
local word_mod = vim.fn.has("mac") == 1 and "M" or "C"
vim.keymap.set({ "n", "x", "o" }, "<" .. word_mod .. "-Left>", "b", { desc = "Previous word" })
vim.keymap.set({ "n", "x", "o" }, "<" .. word_mod .. "-Right>", "w", { desc = "Next word" })
vim.keymap.set("i", "<" .. word_mod .. "-Left>", "<S-Left>", { desc = "Previous word" })
vim.keymap.set("i", "<" .. word_mod .. "-Right>", "<S-Right>", { desc = "Next word" })

-- Delete the previous word with the same modifier. Terminals without the kitty keyboard protocol send Ctrl+Backspace as Ctrl+h.
local word_delete_keys = vim.fn.has("mac") == 1 and { "<M-BS>" } or { "<C-BS>", "<C-h>" }
for _, lhs in ipairs(word_delete_keys) do
    vim.keymap.set({ "i", "c" }, lhs, "<C-w>", { desc = "Delete previous word" })
end

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Better J behavior
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- Toggle comments with Ctrl+/ (some terminals send it as <C-_>)
for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
    vim.keymap.set("n", lhs, "gcc", { remap = true, desc = "Toggle comment" })
    vim.keymap.set("x", lhs, "gc", { remap = true, desc = "Toggle comment" })
end

-- Quick config editing
vim.keymap.set("n", "<leader>rc", function()
    vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath("config") .. "/init.lua"))
end, { desc = "Edit config" })

-- File Explorer
vim.keymap.set("n", "<leader>m", "<Cmd>NvimTreeFocus<CR>", { desc = "Focus on File Explorer" })
vim.keymap.set("n", "<leader>e", "<Cmd>NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })

-- Undo tree is built into nvim 0.12; packadd on first use keeps it out of startup.
vim.keymap.set("n", "<leader>u", function()
    vim.cmd.packadd("nvim.undotree")
    require("undotree").open()
end, { desc = "Toggle undo tree" })

-- The Primeagen keymaps
vim.keymap.set({"n", "v"}, "<leader>d", [["_d]], { desc = "Delete without yanking" })
vim.keymap.set(
    "n",
    "<leader>s",
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
    { desc = "Replace word under cursor" }
)
vim.keymap.set(
    "n",
    "<leader>x",
    "<cmd>!chmod +x %<CR>",
    {
        silent = true,
        desc = "Make current file executable"
    }
)
