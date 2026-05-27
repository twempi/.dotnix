return {
	"yazi.nvim",
	event = "DeferredUIEnter",
	keys = {
		{
			"<leader>e",
			mode = { "n", "v" },
			"<cmd>Yazi<cr>",
			desc = "Open yazi at current file",
		},
		{
			"<leader>E",
			"<cmd>Yazi cwd<cr>",
			desc = "Open yazi at nvim's cwd",
		},
		{
			"<c-up>",
			"<cmd>Yazi toggle<cr>",
			desc = "Resume the last yazi session",
		},
	},
	before = function()
		require("lze").trigger_load({
			"plenary.nvim",
			"snacks.nvim",
		})
		vim.g.loaded_netrwPlugin = 1
	end,
	after = function()
		require("yazi").setup({
			open_for_directories = true,
			keymaps = {
				show_help = "<f1>",
			},
		})
	end,
}
