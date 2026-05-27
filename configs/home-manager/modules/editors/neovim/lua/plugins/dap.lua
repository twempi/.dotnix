return {
	-- Core DAP + UI + virtual text
	{
		"nvim-dap",

		keys = {
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "Debug: Start/Continue",
			},
			{
				"<F1>",
				function()
					require("dap").step_into()
				end,
				desc = "Debug: Step Into",
			},
			{
				"<F2>",
				function()
					require("dap").step_over()
				end,
				desc = "Debug: Step Over",
			},
			{
				"<F3>",
				function()
					require("dap").step_out()
				end,
				desc = "Debug: Step Out",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Debug: Toggle Breakpoint",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint: "))
				end,
				desc = "Debug: Set Breakpoint",
			},
			{
				"<F7>",
				function()
					require("dapui").toggle()
				end,
				desc = "Debug: Toggle UI",
			},
		},

		before = function()
			require("lze").trigger_load({
				"nvim-dap-ui",
				"nvim-dap-virtual-text",
			})
		end,

		after = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- dap-ui setup
			dapui.setup({
				icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
				controls = {
					icons = {
						pause = "⏸",
						play = "▶",
						step_into = "⏎",
						step_over = "⏭",
						step_out = "⏮",
						step_back = "b",
						run_last = "▶▶",
						terminate = "⏹",
						disconnect = "⏏",
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
		"nvim-dap-go",
		ft = "go", -- only load when editing Go files
		before = function()
			require("lze").trigger_load("nvim-dap")
		end,
		after = function()
			require("dap-go").setup()
		end,
	},

	{ "nvim-dap-ui", dep_of = "nvim-dap" },
	{ "nvim-dap-virtual-text", dep_of = "nvim-dap" },
}
