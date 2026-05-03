return {
	-- {
	-- "nvim-mini/mini.nvim",
	-- enabled = true,
	--   version = false,
	-- lazy = true,
	-- },
	{
		"nvim-mini/mini.ai",
		enabled = true,
		version = false,
		event = "VeryLazy",
		opts = {},
	},
	{
		"nvim-mini/mini.icons",
		enabled = true,
		version = false,
		event = "VeryLazy",
		opts = {},
	},
	{
		"nvim-mini/mini.pairs",
		enabled = false,
		version = false,
		event = "VeryLazy",
		opts = {},
	},
	{
		"nvim-mini/mini.surround",
		enabled = true,
		version = false,
		event = "VeryLazy",
		opts = {},
	},
	{
		"nvim-mini/mini.splitjoin",
		enabled = true,
		version = false,
		event = "VeryLazy",
		opts = {
			mappings = {
				toggle = "gS",
				split = "sk",
				join = "sj",
			},
			detect = {
				separator = ", ;",
			},
		},
	},
}
