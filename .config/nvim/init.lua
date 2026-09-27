vim.loader.enable() -- cache compiled Lua modules for a faster startup
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("plugins")
require("languages").setup()
require("config.lsp")
require("config.terminal")
