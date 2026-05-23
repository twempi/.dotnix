return {
	"pxwg/math-conceal.nvim",
	name = "math-conceal-nvim",
	main = "math-conceal",

	ft = {
		"plaintex",
		"tex",
		"context",
		"bibtex",
		"markdown",
		"typst",
	},

	init = function()
		vim.opt.conceallevel = 2
		vim.opt.concealcursor = "nc"
	end,

	opts = {
		conceal = {
			"greek",
			"script",
			"math",
			"font",
			"delim",
			"phy",
		},
		ft = {
			"plaintex",
			"tex",
			"context",
			"bibtex",
			"markdown",
			"typst",
		},
		image = {
			enabled = true,
			filetypes = { "typst", "markdown" },

			-- Size / scale
			math_baseline_pt = 10, -- default 11; lower usually renders larger
			ppi = 300, -- fallback when terminal pixel size is unavailable

			-- Padding / margins
			block_padding_cols = 6, -- default 15; terminal-column side padding for block previews
			block_preview_margin_pt = 3, -- default 6; Typst-side inner margin

			-- Optional styling
			styling_type = "colorscheme", -- "colorscheme", "simple", or "none"

			-- Optional behavior
			live_preview_enabled = true,
			live_preview_debounce = 100,
		},
	},
}
