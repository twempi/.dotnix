return {
	"noice.nvim",
	event = "DeferredUIEnter",
	after = function()
		require("noice").setup({
			cmdline = {
				enabled = true,
				view = "cmdline_popup",
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
}
