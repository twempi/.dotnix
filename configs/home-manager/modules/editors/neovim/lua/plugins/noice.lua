return {
	{
		"noice.nvim",
		event = "DeferredUIEnter",
		after = function()
			require("noice").setup({
				cmdline = {
					enabled = true,
					view = "cmdline_popup",
				},

				views = {
					cmdline_popup = {
						position = {
							row = 3,
							col = "50%",
						},
					},
				},
				-- Disable everything besides the command line
				messages = { enabled = false },
				notify = { enabled = false },
				popupmenu = { enabled = true },
				lsp = {
					progress = { enabled = false },
					hover = { enabled = false },
					signature = { enabled = false },
					message = { enabled = false },
				},
			})
		end,
	},
	{
		"nui.nvim",
		dep_of = "noice.nvim",
	},
}
