return {
	"math-conceal-nvim",

	ft = {
		"plaintex",
		"tex",
		"context",
		"bibtex",
		"markdown",
		"typst",
	},

	before = function()
		vim.opt.conceallevel = 0
	end,

	after = function()
		local has_ui = #vim.api.nvim_list_uis() > 0
		require("math-conceal").setup({
			conceal = {},
			ft = {
				"plaintex",
				"tex",
				"context",
				"bibtex",
				"markdown",
				"typst",
			},
			image = {
				enabled = has_ui,
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
		})
	end,
}
