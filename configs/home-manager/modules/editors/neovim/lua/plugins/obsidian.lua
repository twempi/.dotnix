-- Settings mirror the vault's .obsidian/app.json, daily-notes.json and
-- templates.json, so notes made here land where the Obsidian app puts them.
local vault = vim.fn.expand("~/Documents/notes")

return {
	"obsidian.nvim",
	cmd = "Obsidian",
	event = { { event = { "BufReadPre", "BufNewFile" }, pattern = vault .. "/*.md" } },
	keys = {
		{ "<leader>oo", "<cmd>Obsidian<CR>", desc = "Obsidian commands" },
		{ "<leader>od", "<cmd>Obsidian today<CR>", desc = "Daily note" },
		{ "<leader>of", "<cmd>Obsidian quick_switch<CR>", desc = "Find note" },
		{ "<leader>os", "<cmd>Obsidian search<CR>", desc = "Search notes" },
		{ "<leader>on", "<cmd>Obsidian new<CR>", desc = "New note" },
	},
	after = function()
		require("obsidian").setup({
			legacy_commands = false,
			workspaces = { { name = "notes", path = vault } },

			notes_subdir = "000 Home/Inbox",
			new_notes_location = "notes_subdir",
			-- Obsidian names the file after the title ("Untitled", "Untitled 1", ...).
			note_id_func = function(title, dir)
				local base = title or "Untitled"
				local id, n = base, 0
				while dir and vim.uv.fs_stat(vim.fs.joinpath(tostring(dir), id .. ".md")) do
					n = n + 1
					id = base .. " " .. n
				end
				return id
			end,

			link = { auto_update = true },
			-- Obsidian owns the properties; don't add id/aliases/tags on every save.
			frontmatter = { enabled = false },
			templates = { folder = "999 Templates" },
			-- No template: the vault's "Daily Notes" template is Templater JavaScript,
			-- which obsidian.nvim would paste in unevaluated.
			daily_notes = {
				folder = "300 Personal/Daily",
				workdays_only = false,
			},
			attachments = { folder = "/990 Attachments" },
			picker = { name = "snacks.picker" },

			-- Its conceal check runs before enter_note below sets conceallevel.
			ui = { ignore_conceal_warn = true },
			callbacks = {
				-- The note UI (checkboxes, links) is drawn with conceal, like Live Preview.
				enter_note = function()
					vim.opt_local.conceallevel = 2
				end,
			},
		})
	end,
}
