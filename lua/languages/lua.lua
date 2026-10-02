-- ================================================================================================
-- TITLE : Lua
-- ABOUT : lua and luadoc parsers, lua_ls, luacheck and stylua.
-- ================================================================================================

-- luacheck comes from the system package manager: Mason's build needs luarocks.
return {
	filetypes = { "lua" },
	line_length = 120, -- stylua's column width
	parsers = { "lua", "luadoc" },
	servers = {
		lua_ls = {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = {
							vim.fn.expand("$VIMRUNTIME/lua"),
							vim.fn.expand("$XDG_CONFIG_HOME") .. "/nvim/lua",
						},
					},
				},
			},
		},
	},
	lint = { "luacheck" },
	format = { "stylua" },
	mason = { "lua-language-server", "stylua" },
}
