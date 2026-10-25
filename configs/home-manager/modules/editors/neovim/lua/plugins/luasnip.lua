return {
	{
		"luasnip",
		lazy = false,

		before = function()
			require("lze").trigger_load("friendly-snippets")
		end,

		after = function()
			local luasnip = require("luasnip")

			luasnip.config.set_config({
				history = true,
				enable_autosnippets = true,
				updateevents = "TextChanged,TextChangedI",
				region_check_events = "CursorMoved,CursorMovedI,InsertEnter",
				delete_check_events = "TextChanged,InsertLeave",

				-- Needed for snippets that wrap visual selections.
				-- Change this if it conflicts with your Tab/cmp/tabout setup.
				store_selection_keys = "<Tab>",
			})

			require("luasnip.loaders.from_vscode").lazy_load()

			require("luasnip.loaders.from_lua").lazy_load({
				paths = vim.api.nvim_get_runtime_file("lua/snippets", true),
			})

			luasnip.filetype_extend("rmarkdown", { "markdown" })
			luasnip.filetype_extend("quarto", { "markdown" })
			luasnip.filetype_extend("mdx", { "markdown" })

			local group = vim.api.nvim_create_augroup("LuaSnipCleanup", { clear = true })

			vim.api.nvim_create_autocmd("InsertLeave", {
				group = group,
				callback = function()
					if
						luasnip.session.current_nodes[vim.api.nvim_get_current_buf()]
						and not luasnip.session.jump_active
					then
						luasnip.unlink_current()
					end
				end,
			})
		end,
	},

	-- The nixpkgs plugin has no setup(): its plugin/ script registers the `tex`
	-- snippets with LuaSnip when it loads. Its math triggers call VimTeX's
	-- in_mathzone(), which needs Vim syntax (see user_treesitter_start).
	{
		"luasnip-latex-snippets.nvim",
		lazy = true,
		ft = {
			"tex",
			"plaintex",
			"latex",
		},
	},
}
