return {
	"render-markdown.nvim",
	ft = { "markdown" },
	after = function()
		require("render-markdown").setup({
			preset = "obsidian",
			latex = { enabled = false },
			html = {
				comment = { conceal = false },
			},
			completions = {
				lsp = { enabled = true },
			},
		})
	end,
}
