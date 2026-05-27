return {
	-- {
	-- "nvim-mini/mini.nvim",
	-- enabled = true,
	--   version = false,
	-- lazy = true,
	-- },
	{
		"mini.ai",
		event = "DeferredUIEnter",
		after = function()
			require("mini.ai").setup({})
		end,
	},
	{
		"mini.icons",
		event = "DeferredUIEnter",
		after = function()
			require("mini.icons").setup({})
		end,
	},
	{
		"mini.pairs",
		enabled = false,
		event = "DeferredUIEnter",
		after = function()
			require("mini.pairs").setup({})
		end,
	},
	{
		"mini.surround",
		event = "DeferredUIEnter",
		after = function()
			require("mini.surround").setup({})
		end,
	},
	{
		"mini.splitjoin",
		event = "DeferredUIEnter",
		after = function()
			require("mini.splitjoin").setup({
				mappings = {
					toggle = "gS",
					split = "sk",
					join = "sj",
				},
				detect = {
					separator = ", ;",
				},
			})
		end,
	},
}
