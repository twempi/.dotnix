return {
	{ "nvim-web-devicons", lazy = false },

	{
		"base46",
		lazy = false,
		priority = 1000,
		after = function()
			require("base46").load_all_highlights()
		end,
	},

	{
		"nvchad-ui",
		lazy = false,
		before = function()
			require("lze").trigger_load({
				"nvim-web-devicons",
				"base46",
			})
		end,
		after = function()
			require("nvchad")
		end,
	},
}
