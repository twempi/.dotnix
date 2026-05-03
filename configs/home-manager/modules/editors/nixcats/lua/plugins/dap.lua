return {
  -- Core DAP + UI + virtual text
  {
    "mfussenegger/nvim-dap",
    enabled = true,

    -- let lazy load on first key use
    keys = {
      { "<F5>",     function() require("dap").continue() end,          desc = "Debug: Start/Continue" },
      { "<F1>",     function() require("dap").step_into() end,         desc = "Debug: Step Into" },
      { "<F2>",     function() require("dap").step_over() end,         desc = "Debug: Step Over" },
      { "<F3>",     function() require("dap").step_out() end,          desc = "Debug: Step Out" },
      { "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
      {
        "<leader>B",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint: "))
        end,
        desc = "Debug: Set Breakpoint",
      },
      { "<F7>",     function() require("dapui").toggle() end,          desc = "Debug: Toggle UI" },
    },

    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
    },

    config = function()
      local dap   = require("dap")
      local dapui = require("dapui")

      -- dap-ui setup
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
        controls = {
          icons = {
            pause       = "⏸",
            play        = "▶",
            step_into   = "⏎",
            step_over   = "⏭",
            step_out    = "⏮",
            step_back   = "b",
            run_last    = "▶▶",
            terminate   = "⏹",
            disconnect  = "⏏",
          },
        },
      })

      -- auto-open / close dap-ui
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- virtual text setup
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        clear_on_continue = false,
        display_callback = function(variable, _, _, _, opts)
          if opts.virt_text_pos == "inline" then
            return " = " .. variable.value
          end
          return variable.name .. " = " .. variable.value
        end,
        virt_text_pos = (vim.fn.has("nvim-0.10") == 1) and "inline" or "eol",
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil,
      })
    end,
  },

  -- Go adapter
  {
    "leoluz/nvim-dap-go",
    enabled = true,
    dependencies = { "mfussenegger/nvim-dap" },
    ft = "go",   -- only load when editing Go files
    config = function()
      require("dap-go").setup()
    end,
  },
}
