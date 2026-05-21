return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },

	config = function()
		local capabilities = vim.lsp.protocol.make_client_capabilities()

		local ok, blink = pcall(require, "blink.cmp")
		if ok and blink.get_lsp_capabilities then
			capabilities = blink.get_lsp_capabilities(capabilities)
		end

		local on_attach = function(client, bufnr)
			-- Formatting is handled by conform.nvim, not LSP servers.
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false

			local map = function(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, {
					buffer = bufnr,
					silent = true,
					desc = desc,
				})
			end

			map("n", "gd", vim.lsp.buf.definition, "Go to definition")
			map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
			map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
			map("n", "gr", vim.lsp.buf.references, "References")
			map("n", "K", vim.lsp.buf.hover, "Hover documentation")

			map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")
			map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
		end

		vim.diagnostic.config({
			virtual_text = true,
			signs = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		local function nixcats_extra(path, fallback)
			if type(nixCats) == "table" and type(nixCats.extra) == "function" then
				local value = nixCats.extra(path)
				if value ~= nil then
					return value
				end
			end
			return fallback
		end

		local default_config = {
			capabilities = capabilities,
			on_attach = on_attach,
		}

		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim", "nixCats" },
					},
					workspace = {
						checkThirdParty = false,
						library = {
							vim.env.VIMRUNTIME,
						},
					},
					telemetry = {
						enable = false,
					},
				},
			},
		})

		vim.lsp.config("nixd", {
			capabilities = capabilities,
			on_attach = on_attach,
			cmd = { "nixd" },
			filetypes = { "nix" },
			root_markers = { "flake.nix", ".git" },
			settings = {
				nixd = {
					nixpkgs = {
						expr = nixcats_extra("nixdExtras.nixpkgs", "import <nixpkgs> { }"),
					},
					formatting = {
						command = { "alejandra" },
					},
					options = {
						nixos = {
							expr = nixcats_extra("nixdExtras.nixosOptions", ""),
						},
						["home-manager"] = {
							expr = nixcats_extra("nixdExtras.homeManagerOptions", ""),
						},
					},
				},
			},
		})

		vim.lsp.config("pyright", default_config)

		vim.lsp.config("ts_ls", default_config)

		vim.lsp.config("gopls", default_config)

		vim.lsp.config("marksman", default_config)

		vim.lsp.config("jsonls", default_config)

		vim.lsp.config("yamlls", default_config)

		vim.lsp.config("taplo", default_config)

		vim.lsp.config("clangd", {
			capabilities = capabilities,
			on_attach = on_attach,
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--completion-style=detailed",
			},
		})

		vim.lsp.config("bashls", default_config)

		vim.lsp.config("tinymist", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				exportPdf = "onType",
				semanticTokens = "enable",
				formatterMode = "typstyle",
			},
		})

		vim.lsp.config("texlab", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				texlab = {
					build = {
						executable = "latexmk",
						args = {
							"-pdf",
							"-interaction=nonstopmode",
							"-synctex=1",
							"%f",
						},
						onSave = false,
					},
					forwardSearch = {
						executable = "zathura",
						args = {
							"--synctex-forward",
							"%l:%c:%f",
							"%p",
						},
					},
				},
			},
		})

		vim.lsp.config("arduino_language_server", default_config)

		vim.lsp.config("asm_lsp", {
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "asm", "nasm", "masm", "gas", "s", "S" },
		})

		vim.lsp.enable({
			"lua_ls",
			"nixd",
			"pyright",
			"ts_ls",
			"gopls",
			"marksman",
			"jsonls",
			"yamlls",
			"taplo",
			"clangd",
			"bashls",
			"tinymist",
			"texlab",
			"arduino_language_server",
			"asm_lsp",
		})
	end,
}
