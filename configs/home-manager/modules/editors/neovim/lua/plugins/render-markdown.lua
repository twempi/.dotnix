return {
	{
		"render-markdown.nvim",
		ft = { "markdown" },
		after = function()
			require("render-markdown").setup({
				preset = "obsidian",
				checkbox = {
				enabled = true,
				custom = {
					in_progress = {
						raw = "[~]",
						rendered = "󰥔 ",
						highlight = "RenderMarkdownTodo",
					},
					important = {
						raw = "[!]",
						rendered = "󰓎 ",
						highlight = "DiagnosticWarn",
					},
					forwarded = {
						raw = "[>]",
						rendered = " ",
						highlight = "DiagnosticInfo",
					},
					strikethrough = {
						raw = "[/]",
						rendered = " ",
						highlight = "DiagnosticError",
						scope_highlight = "@markup.strikethrough",
					},
				},
			},
			latex = { enabled = false },
			html = {
				enabled = true,
				comment = {
					conceal = false,
				},
			},
			render_modes = true,
			anti_conceal = {
				enabled = true,
				ignore = {
					code_background = true,
					sign = true,
				},
				above = 0,
				below = 0,
			},
			completions = {
				lsp = { enabled = true },
				blink = { enabled = true },
			},
				pipe_table = {
					enabled = true,
				},
			})
		end,
	},
}
