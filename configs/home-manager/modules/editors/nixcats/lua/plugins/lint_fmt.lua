return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				go = { "golangcilint" },
			}

			local grp = vim.api.nvim_create_augroup("UserLint", { clear = true })

			vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufReadPost" }, {
				group = grp,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},

	{
		"stevearc/conform.nvim",
		event = { "BufReadPost", "BufNewFile" },
		keys = {
			{
				"<leader>FF",
				function()
					require("conform").format({
						lsp_fallback = true,
						async = false,
						timeout_ms = 1000,
					})
				end,
				mode = { "n", "v" },
				desc = "[F]ormat [F]ile",
			},
		},
		opts = {
			formatters_by_ft = {
				-- Lua
				lua = { "stylua" },

				-- Python
				python = { "black" },

				-- Go
				go = { "gofmt" },

				-- JavaScript / TypeScript
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },

				-- C / C++
				c = { "clang_format" },
				cpp = { "clang_format" },

				-- Shell
				sh = { "shfmt" },
				bash = { "shfmt" },

				-- Nix
				nix = { "alejandra" },

				-- Typst
				typst = { "typstyle" },

				-- LaTeX
				tex = { "latexindent" },

        -- Assembly
        asm = {"asmfmt"},

        -- Arduino
        arduino = {"clang_format"},
			},
		},
		config = function(_, opts)
			require("conform").setup(opts)
		end,
	},
}
