-- Filetypes where word suggestions help and snippets may follow a trigger character like `\`.
local prose_filetypes = { markdown = true, text = true, gitcommit = true, typst = true, tex = true }

-- Note names must rank first here, and word guesses would otherwise bury them.
local function in_wikilink()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	return vim.bo.filetype == "markdown" and vim.api.nvim_get_current_line():sub(1, col):match("%[%[[^%]]*$") ~= nil
end

local function in_frontmatter(row)
	local lines = vim.api.nvim_buf_get_lines(0, 0, row - 1, false)
	return lines[1] == "---" and not vim.list_contains(vim.list_slice(lines, 2), "---")
end

-- Where the tag being typed starts on a frontmatter `tags` value, or nil anywhere else.
local function frontmatter_tag_start()
	local cursor = vim.api.nvim_win_get_cursor(0)
	-- obsidian-ls attaches only inside the vault, which is what the tag search scans.
	if not vim.lsp.get_clients({ name = "obsidian-ls", bufnr = 0 })[1] or not in_frontmatter(cursor[1]) then
		return nil
	end

	local before = vim.api.nvim_get_current_line():sub(1, cursor[2])
	local start = before:match("^tags:%s.-()#?[^%s,%[%]#]*$")
	if start then
		return start - 1
	end

	start = before:match("^%s*%-%s+()#?%S*$")
	for row = cursor[1] - 1, 1, -1 do
		local key = start and vim.fn.getline(row):match("^([%w_-]+):")
		if key then
			return key == "tags" and start - 1 or nil
		end
	end
	return nil
end

-- obsidian-ls only completes tags on indented `- ` lines, not on the `tags:` line itself.
-- Preloaded because blink loads sources with require().
package.preload["dotnix.frontmatter_tags"] = function()
	local source = {}

	function source.new()
		return source
	end

	function source:get_completions(ctx, callback)
		local start = frontmatter_tag_start()
		local line = ctx.cursor[1] - 1
		require("obsidian.search").find_tags_async("", function(locations)
			local seen, items = {}, {}
			for _, location in ipairs(locations) do
				local tag = location.tag
				if start and not seen[tag:lower()] then
					seen[tag:lower()] = true
					items[#items + 1] = {
						label = tag,
						kind = vim.lsp.protocol.CompletionItemKind.Keyword,
						-- Replaces any typed `#`, which would turn the YAML value into a comment.
						textEdit = {
							newText = tag,
							range = {
								start = { line = line, character = start },
								["end"] = { line = line, character = ctx.cursor[2] },
							},
						},
					}
				end
			end
			callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
		end)
	end

	return source
end

-- Obsidian ignores unquoted property links and obsidian-ls skips frontmatter, so marksman's
-- item has to supply the quotes. Its edit also stops short of the auto-closed `]]`.
local function quote_property_links(ctx, items)
	if vim.bo.filetype ~= "markdown" or not in_frontmatter(ctx.cursor[1]) then
		return items
	end

	local col = ctx.cursor[2]
	local start = ctx.line:sub(1, col):match('()"?%[%[[^%[%]"]*$')
	if not start then
		return items
	end

	local closing = #ctx.line:sub(col + 1):match('^%]*"?')
	for _, item in ipairs(items) do
		local edit = item.client_name == "marksman" and item.textEdit
		if edit and vim.startswith(edit.newText, "[[") then
			edit.newText = '"' .. edit.newText .. '"'
			edit.range.start.character = vim.str_utfindex(ctx.line, "utf-16", start - 1, false)
			edit.range["end"].character = vim.str_utfindex(ctx.line, "utf-16", col + closing, false)
		end
	end
	return items
end

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
				"tabout.nvim",
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

			-- Latex Suite's matrix shortcuts and tabout in markdown math.
			local function latex_suite(name)
				return function()
					return require("latex_suite")[name]()
				end
			end

			local opts = {
				snippets = { preset = "luasnip" },
				cmdline = { enabled = true },
				keymap = {
					preset = "default",
					["<CR>"] = { "accept", latex_suite("enter"), "fallback" },
					["<S-CR>"] = { latex_suite("exit"), "fallback" },
					["<Tab>"] = {
						luasnip_expand_or_jump,
						latex_suite("tab"),
						"fallback",
					},
					["<S-Tab>"] = {
						luasnip_jump_back,
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
					default = function()
						if frontmatter_tag_start() then
							return { "frontmatter_tags" }
						end
						return { "lsp", "path", "snippets", "buffer", "spell" }
					end,
					per_filetype = {
						lua = { inherit_defaults = true, "lazydev" },
					},
					providers = {
						frontmatter_tags = { name = "Tags", module = "dotnix.frontmatter_tags" },
						lsp = { transform_items = quote_property_links },
						snippets = {
							-- Otherwise `s.` buries a struct's fields under every snippet.
							should_show_items = function(ctx)
								return not in_wikilink()
									and (prose_filetypes[vim.bo.filetype] or ctx.trigger.initial_kind ~= "trigger_character")
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
									return vim.wo.spell and prose_filetypes[vim.bo.filetype] == true and not in_wikilink()
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

			local autopairs = require("nvim-autopairs")
			autopairs.setup(opts)

			-- Latex Suite's autoDelete$: Backspace in blank inline math `$|$` deletes both.
			-- Never inserted or skipped over, only deleted.
			local Rule, cond = require("nvim-autopairs.rule"), require("nvim-autopairs.conds")
			autopairs.add_rule(
				Rule("$", "$", "markdown")
					:with_pair(cond.none())
					:with_move(cond.none())
					:with_cr(cond.none())
					:with_del(function(o)
						return o.line:sub(o.col - 1, o.col - 1) ~= "$" and o.line:sub(o.col + 2, o.col + 2) ~= "$"
					end)
			)
		end,
	},
}
