return {
	"Prgebish/sigil.nvim",
	enabled = true,
	config = function()
		require("sigil").setup({
			filetypes = { "tex", "plaintex", "latex", "typst" },
			filetype_symbols = {
				tex = {
					{ pattern = "\\alpha", replacement = "α", boundary = "left" },
					{ pattern = "\\beta", replacement = "β", boundary = "left" },
					{ pattern = "\\to", replacement = "→" },
					{ pattern = "\\leq", replacement = "≤" },
				},
				typst = {
					math = {
						-- Only prettified inside $...$
						{ pattern = "alpha", replacement = "α", boundary = "left" },
						{ pattern = "sum", replacement = "∑", boundary = "left" },
					},
					text = {
						-- Only prettified outside math
					},
					any = {
						-- Prettified everywhere
						{ pattern = "->", replacement = "→" },
					},
				},
			},
		})
	end,
}
