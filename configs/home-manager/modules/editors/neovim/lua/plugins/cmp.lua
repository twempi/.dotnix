-- Filetypes where word suggestions help and snippets may follow a trigger character like `\`.
local prose_filetypes = { markdown = true, text = true, gitcommit = true, typst = true, tex = true }

return {
	{
		"blink.cmp",
		event = { "InsertEnter", "CmdLineEnter" },
		before = function()
			require("lze").trigger_load({
				"luasnip",
				"friendly-snippets",
				"blink-cmp-spell",
				"nvim-autopairs",
			})
		end,
		after = function()
			-- blink runs these inside expr mappings (textlock), so the buffer
			-- change has to be scheduled, as blink's own snippet_forward does.
			local function luasnip_expand_or_jump()
				local ok, luasnip = pcall(require, "luasnip")
				if ok and luasnip.expand_or_jumpable() then
					vim.schedule(luasnip.expand_or_jump)
					return true
				end
				return false
			end

			local function luasnip_jump_back()
				local ok, luasnip = pcall(require, "luasnip")
				if ok and luasnip.jumpable(-1) then
					vim.schedule(function()
						luasnip.jump(-1)
					end)
					return true
				end
				return false
			end

			local opts = {
				snippets = { preset = "luasnip" },
				cmdline = { enabled = true },
				keymap = {
					preset = "default",
					["<CR>"] = { "accept", "fallback" },
					["<Tab>"] = {
						luasnip_expand_or_jump,
						"select_next",
						"fallback",
					},
					["<S-Tab>"] = {
						luasnip_jump_back,
						"select_prev",
						"fallback",
					},
				},
				appearance = { nerd_font_variant = "mono" },
				signature = { enabled = false },
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
					per_filetype = {
						lua = { inherit_defaults = true, "lazydev" },
					},
					providers = {
						snippets = {
							-- Otherwise `s.` buries a struct's fields under every snippet.
							should_show_items = function(ctx)
								return prose_filetypes[vim.bo.filetype] or ctx.trigger.initial_kind ~= "trigger_character"
							end,
						},
						lazydev = {
							name = "LazyDev",
							module = "lazydev.integrations.blink",
							score_offset = 100,
						},
						spell = {
							name = "Spell",
							module = "blink-cmp-spell",
							opts = {
								-- 'spell' is on everywhere to check comments, so it can't gate this alone:
								-- word guesses would outrank clangd and other servers in code.
								enable_in_context = function()
									return vim.wo.spell and prose_filetypes[vim.bo.filetype] == true
								end,
							},
						},
					},
				},
			}

			require("blink.cmp").setup(opts)
		end,
	},

	{ "blink-cmp-spell", dep_of = "blink.cmp" },

	-- Teaches lua_ls the Neovim runtime and the plugins a Lua file requires, and
	-- adds module-name completion for `require()` (see the lazydev source above).
	{
		"lazydev.nvim",
		ft = "lua",
		after = function()
			require("lazydev").setup()
		end,
	},

	{
		"nvim-autopairs",
		event = "InsertEnter",
		after = function()
			local opts = {
				fast_wrap = {},
				disable_filetype = { "TelescopePrompt", "vim" },
			}

			require("nvim-autopairs").setup(opts)
		end,
	},
}
