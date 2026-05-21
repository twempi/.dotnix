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
	},
}
