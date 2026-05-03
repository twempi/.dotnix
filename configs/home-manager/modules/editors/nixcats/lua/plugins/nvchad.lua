return {
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	{
		"nvchad/base46",
		lazy = false,
		priority = 1000,
		config = function()
			require("base46").load_all_highlights()
		end,
	},

	{
		"nvchad/ui",
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"nvchad/base46",
		},
		config = function()
			require("nvchad")
		end,
	},
}
