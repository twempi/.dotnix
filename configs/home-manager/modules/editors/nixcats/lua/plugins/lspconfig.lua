return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },

	config = function()
		-- =========================
		-- Capabilities (blink.cmp)
		-- =========================
		local capabilities = vim.lsp.protocol.make_client_capabilities()

		local ok, blink = pcall(require, "blink.cmp")
		if ok and blink.get_lsp_capabilities then
			capabilities = blink.get_lsp_capabilities(capabilities)
		end

		-- =========================
		-- on_attach
		-- =========================
		local on_attach = function(client, bufnr)
			-- 🔒 Disable ALL LSP formatting
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

			map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
			map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")

			-- Formatting is handled ONLY by conform.nvim
			map("n", "<leader>f", function()
				require("conform").format({
					lsp_fallback = true,
					async = true,
					timeout_ms = 1000,
				})
			end, "Format buffer")
		end

		-- =========================
		-- Diagnostics UI
		-- =========================
		vim.diagnostic.config({
			virtual_text = true,
			signs = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		-- =========================
		-- LSP servers
		-- =========================

		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = { checkThirdParty = false },
					telemetry = { enable = false },
				},
			},
		})

		vim.lsp.config("pyright", {
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
		})

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

		vim.lsp.config("bashls", {
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("nil_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				["nil"] = {
					nix = {
						flake = {
							autoArchive = true,
						},
					},
				},
			},
		})

		vim.lsp.config("tinymist", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				exportPdf = "onType",
				semanticTokens = "enable",
				formatterMode = "typestyle",
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

		vim.lsp.config("arduino-language-server", {
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("asm_lsp", {
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "asm", "nasm", "masm", "gas", "s", "S" },
		})

		vim.lsp.enable({
			"lua_ls",
			"pyright",
			"ts_ls",
			"clangd",
			"bashls",
			"nil_ls",
			"tinymist",
			"texlab",
			"arduino-language-server",
			"asm_lsp",
		})
	end,
}
