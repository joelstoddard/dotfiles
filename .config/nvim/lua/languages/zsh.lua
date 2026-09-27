-- ================================================================================================
-- TITLE : Zsh
-- ABOUT : highlights with the bash parser; bashls (bash.lua) also serves zsh.
-- ================================================================================================

-- shellcheck does not support zsh, so zsh only borrows the bash parser.
return {
	register = { bash = { "zsh" } },
}
