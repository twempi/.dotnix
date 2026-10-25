return {
	{
		"nvim-lint",
		event = { "BufReadPost", "BufNewFile" },
		after = function()
			local lint = require("lint")

			-- chktex exits 2 whenever it reports findings; don't toast that as a failure.
			lint.linters.chktex.ignore_exitcode = true

			lint.linters_by_ft = {
				-- Python
				python = { "ruff" },

				-- Go
				go = { "golangcilint" },

				-- JavaScript / TypeScript
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },

				-- Shell is linted by bashls, which runs shellcheck itself.

				-- Nix
				nix = { "statix", "deadnix" },

				-- LaTeX
				tex = { "chktex" },
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
		"conform.nvim",
		event = { "BufReadPost", "BufNewFile" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({
						lsp_format = "never",
						async = false,
						timeout_ms = 1000,
					})
				end,
				mode = { "n", "v" },
				desc = "Format file",
			},
		},
		after = function()
			require("conform").setup({
				formatters_by_ft = {
				-- Lua
				lua = { "stylua" },

				-- Python
				python = { "isort", "black" },

				-- Go
				go = { "goimports", "gofmt" },

				-- JavaScript / TypeScript
				javascript = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },

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
				asm = { "asmfmt" },
			},

				formatters = {
					-- Without this latexindent writes an indent.log into the working directory.
					latexindent = { prepend_args = { "-g", "/dev/null" } },
				},
			})
		end,
	},
}
