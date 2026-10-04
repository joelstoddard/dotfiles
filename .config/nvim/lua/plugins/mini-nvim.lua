-- ================================================================================================
-- TITLE : mini.nvim
-- LINKS :
--   > github : https://github.com/nvim-mini/mini.nvim
-- ABOUT : Library of 40+ independent Lua modules.
-- ================================================================================================

-- Leaves an/in to nvim 0.12's treesitter selection. a/i objects still reach the next match (cover_or_next).
require("mini.ai").setup({ mappings = { around_next = "", inside_next = "" } })
require("mini.comment").setup()
require("mini.surround").setup()
require("mini.cursorword").setup()
require("mini.indentscope").setup()
require("mini.pairs").setup()
require("mini.trailspace").setup()
require("mini.bufremove").setup()
require("mini.notify").setup()

local sessions = require("mini.sessions")
sessions.setup()
-- mini.sessions' own autoread warns on every start without a session, so restore ./Session.vim only if it exists.
vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("LocalSessionRead", { clear = true }),
	nested = true,
	once = true,
	callback = function()
		local empty_start = vim.fn.argc() == 0 and vim.api.nvim_buf_line_count(0) == 1 and vim.fn.getline(1) == ""
		if empty_start and sessions.detected[sessions.config.file] then
			sessions.read(sessions.config.file)
		end
	end,
})
vim.keymap.set("n", "<leader>ws", function()
	sessions.write(sessions.config.file)
end, { desc = "Write local session (Session.vim)" })

local icons = require("mini.icons")
-- Compose files, Chart.yaml and manifests would otherwise get the plain YAML icon. MiniIconsBlue matches mini.icons'
-- own Dockerfile and Helm icons, which the theme keeps grey.
local docker = { glyph = "\u{F0868}", hl = "MiniIconsBlue" }
local helm = { glyph = "\u{F0833}", hl = "MiniIconsBlue" }
local kubernetes = { glyph = "\u{F10FE}", hl = "MiniIconsBlue" }
icons.setup({
	filetype = {
		["yaml.docker-compose"] = docker,
		["yaml.helm-values"] = helm,
		["yaml.kubernetes"] = kubernetes,
	},
	file = {
		["docker-compose.yml"] = docker,
		["docker-compose.yaml"] = docker,
		["compose.yml"] = docker,
		["compose.yaml"] = docker,
		["Chart.yaml"] = helm,
	},
	extension = {
		["k8s.yaml"] = kubernetes,
		["k8s.yml"] = kubernetes,
	},
})
icons.mock_nvim_web_devicons()

local diff = require("mini.diff")
diff.setup({ view = { style = "sign", signs = { add = "▎", change = "▎", delete = "▎" } } })
local git = require("mini.git")
git.setup()
-- mini.diff raises an error for buffers without git reference text (untracked, or outside a repo).
local function tracked()
	local data = diff.get_buf_data()
	if data and data.ref_text then
		return true
	end
	vim.notify("(mini.diff) buffer is not tracked by git", vim.log.levels.INFO)
	return false
end
-- ]h and [h come from mini.diff's default mappings.
vim.keymap.set("n", "<leader>hs", function()
	return tracked() and diff.operator("apply") .. "gh" or ""
end, { expr = true, remap = true, desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hp", function()
	if tracked() then
		diff.toggle_overlay()
	end
end, { desc = "Toggle diff overlay" })
vim.keymap.set("n", "<leader>hb", git.show_at_cursor, { desc = "Git blame/show at cursor" })

local move = require("mini.move")
move.setup()
-- mini.move accepts one key for each action, so these maps add Alt+Arrow and keep the default Alt+hjkl.
-- macOS leaves out Option+Left/Right, which jump by word there (see config/keymaps.lua).
local arrows = { Down = "down", Up = "up" }
if vim.fn.has("mac") == 0 then
	arrows.Left, arrows.Right = "left", "right"
end
for key, dir in pairs(arrows) do
	vim.keymap.set("n", "<M-" .. key .. ">", function()
		move.move_line(dir)
	end, { desc = "Move line " .. dir })
	vim.keymap.set("x", "<M-" .. key .. ">", function()
		move.move_selection(dir)
	end, { desc = "Move selection " .. dir })
end
