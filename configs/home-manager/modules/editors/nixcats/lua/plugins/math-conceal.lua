return {
	"pxwg/math-conceal.nvim",
	branch = "preview",
	build = "cargo build --release --manifest-path service/Cargo.toml",
	name = "math-conceal-nvim",
	main = "math-conceal",

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
		},
	},
}
