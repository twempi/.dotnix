return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		enabled = true,
		ft = { "markdown" },
		opts = {
			checkbox = {
				enabled = true,
				custom = {
					todo = {
						raw = "[~]",
						rendered = "󰥔 ",
						highlight = "RenderMarkdownTodo",
					},
					important = {
						raw = "[s]",
						rendered = "󰓎 ",
						highlight = "DiagnosticWarn",
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
		},
	},
}
