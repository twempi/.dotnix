return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	enabled = true,
	opts = {
		preset = "helix",
		win = {
			title = false,
			padding = { 1, 2 },
		},
		spelling = {
			enabled = true,
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
		wk.add({
			{ "<leader>b", group = "[b]uffers" },
			{ "<leader>c", group = "[c]ode" },
			{ "<leader>d", group = "[d]ebug" },
			{ "<leader>e", group = "[e]xplorer" },
			{ "<leader>f", group = "[f]ind" },
			{ "<leader>g", group = "[g]it" },
			{ "<leader>l", group = "[l]atex" },
			{ "<leader>o", group = "[o]bsidian" },
			{ "<leader>s", group = "[s]earch" },
			{ "<leader>t", group = "[t]ypst" },
			{ "<leader>u", group = "[u]i" },
			{ "<leader>w", group = "[w]orkspace" },
			{ "<leader>x", group = "diagnostics/lists" },
		})
	end,
}
