-- ================================================================================================
-- TITLE : zbirenbaum/copilot
-- LINKS : https://github.com/zbirenbaum/copilot.lua
--   > github : https://github.com/zbirenbaum/copilot.lua
-- ABOUT : Pure lua Copilot integration.
-- ================================================================================================

return {
  "zbirenbaum/copilot.lua",
  requires = {
    "copilotlsp-nvim/copilot-lsp",
  },
  init = function()
    vim.g.copilot_nes_debounce = 500
  end,
  config = function()
    require('copilot').setup({
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>"
        },
        layout = {
          position = "bottom", -- | top | left | right | bottom |
          ratio = 0.4
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = false,
        hide_during_completion = true,
        debounce = 75,
        trigger_on_accept = true,
        keymap = {
          accept = "<M-l>",
          accept_word = false,
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      nes = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept_and_goto = "<leader>p",
          accept = false,
          dismiss = "<Esc>",
        },
      },
      auth_provider_url = nil,
      logger = {
        file = vim.fn.stdpath("log") .. "/copilot-lua.log",
        file_log_level = vim.log.levels.OFF,
        print_log_level = vim.log.levels.WARN,
        trace_lsp = "off",
        trace_lsp_progress = false,
        log_lsp_messages = false,
      },
      copilot_node_command = 'node',
      workspace_folders = {},
      copilot_model = "",
      disable_limit_reached_message = false,
      root_dir = function()
        return vim.fs.dirname(vim.fs.find(".git", { upward = true })[1])
      end,
      should_attach = function(_, _)
        local logger = require("copilot.logger")
        if not vim.bo.buflisted then
          logger.debug("not attaching, buffer is not 'buflisted'")
          return false
        end

        if vim.bo.buftype ~= "" then
          logger.debug("not attaching, buffer 'buftype' is " .. vim.bo.buftype)
          return false
        end

        return true
      end,
      server = {
        type = "nodejs",
        custom_server_filepath = nil,
      },
      server_opts_overrides = {},
    })
  end,
}
