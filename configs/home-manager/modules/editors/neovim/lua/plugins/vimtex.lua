return {
	"vimtex",
	lazy = false,
	before = function()
		vim.g.tex_flavor = "latex"
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_view_general_viewer = "zathura"
		vim.g.vimtex_view_general_options = "--synctex-forward @line:@col:@tex --unique file:@pdf"
		vim.g.vimtex_view_forward_search_on_start = false
		vim.g.vimtex_compiler_latexmk = {
			aux_dir = "build",
		}
	end,

	keys = {
		{ "<leader>l", "<nop>", desc = "[l]atex" },
	},
}
