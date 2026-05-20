return {
	{
		"saghen/blink.cmp",
		enabled = true,
		event = { "InsertEnter", "CmdLineEnter" },
		dependencies = {
			{ "L3MON4D3/LuaSnip", name = "luasnip" },
			"rafamadriz/friendly-snippets",
			"ribru17/blink-cmp-spell",
			"windwp/nvim-autopairs",
		},
		opts_extend = { "sources.default" },
		opts = {
			snippets = { preset = "luasnip" },
			cmdline = { enabled = true },
			keymap = {
				preset = "default",
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
			},
			appearance = { nerd_font_variant = "mono" },
			signature = { enabled = true },
			completion = {
				menu = { border = "rounded" },
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
					window = { border = "rounded" },
				},
			},
			sources = {
				default = {
					"lsp",
					"path",
					"snippets",
					"buffer",
					"spell",
				},
				providers = {
					spell = {
						name = "Spell",
						module = "blink-cmp-spell",
						opts = {
							enable_in_context = function()
								return vim.wo.spell
							end,
						},
					},
				},
			},
		},
		config = function(_, opts)
			require("blink.cmp").setup(opts)
		end,
	},

	{
		"windwp/nvim-autopairs",
		enabled = true,
		event = "InsertEnter",
		opts = {
			fast_wrap = {},
			disable_filetype = { "TelescopePrompt", "vim" },
		},
		config = function(_, opts)
			require("nvim-autopairs").setup(opts)
		end,
	},
}
