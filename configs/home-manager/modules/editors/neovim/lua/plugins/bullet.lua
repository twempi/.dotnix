return {
	"bullets.vim",
	ft = { "markdown", "text", "scratch", "gitcommit", "typst" },
	before = function()
		-- Limit bullets.vim to these filetypes (matches your ft list)
		vim.g.bullets_enabled_file_types = { "markdown", "text", "gitcommit", "scratch", "typst" }
		-- Since v2.0.0 bullets are DISABLED in empty buffers by default; flip to 1 if you want them:
		vim.g.bullets_enable_in_empty_buffers = 1
	end,
}
