return {
	"L3MON4D3/LuaSnip",
	name = "luasnip",
	enabled = true,
	lazy = false,
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	config = function()
		local luasnip = require("luasnip")

		luasnip.config.set_config({
			history = true,
			updateevents = "TextChanged,TextChangedI",
			enable_autosnippets = true,
			region_check_events = "InsertEnter",
			delete_check_events = "TextChanged,InsertLeave",
		})

		require("luasnip.loaders.from_vscode").lazy_load()
		require("luasnip.loaders.from_lua").lazy_load({
			paths = vim.api.nvim_get_runtime_file("lua/snippets", true),
		})

		vim.api.nvim_create_autocmd("InsertLeave", {
			callback = function()
				if
					luasnip.session.current_nodes[vim.api.nvim_get_current_buf()] and not luasnip.session.jump_active
				then
					luasnip.unlink_current()
				end
			end,
		})
	end,
}
