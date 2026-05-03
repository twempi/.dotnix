local M = {}

M.base46 = {
	theme = "catppuccin", --catppuccin, rosepine
	transparency = true,
}

M.ui = {
	cmp = {
		style = "atom_colored",
		abbr_maxwidth = 60,
		format_colors = { lsp = true, icon = "󱓻" },
	},

	statusline = {
		theme = "vscode_colored",
	},

	tabufline = {
		enabled = true,
		lazyload = false,
		order = { "treeOffset", "buffers", "tabs", "btns" },
		modules = nil,
		bufwidth = 21,
	},
}

M.colorify = {
	enabled = true,
	mode = "virtual", -- fg, bg, virtual
	virt_text = "󱓻 ",
	highlight = { hex = true, lspvars = true },
}

M.term = {
  base46_colors = true,
}

return M
