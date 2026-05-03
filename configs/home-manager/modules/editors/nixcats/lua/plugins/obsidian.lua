local prefix = "<leader>o"

return {
	{
		"obsidian-nvim/obsidian.nvim",
		enabled = true,
		ft = { "markdown" },

		keys = {
			{ prefix, "<Nop>", desc = "[o]bsidian" },
			{ prefix .. "o", "<cmd>Obsidian open<CR>", desc = "Open on App" },
			{ prefix .. "g", "<cmd>Obsidian search<CR>", desc = "Grep" },
			{ prefix .. "n", "<cmd>Obsidian new<CR>", desc = "New Note" },
			{ prefix .. "N", "<cmd>Obsidian new_from_template<CR>", desc = "New Note (Template)" },
			{ prefix .. "<space>", "<cmd>Obsidian quick_switch<CR>", desc = "Find Files" },
			{ prefix .. "b", "<cmd>Obsidian backlinks<CR>", desc = "Backlinks" },
			{ prefix .. "t", "<cmd>Obsidian tags<CR>", desc = "Tags" },
			{ prefix .. "T", "<cmd>Obsidian template<CR>", desc = "Template" },
			{ prefix .. "L", "<cmd>Obsidian link<CR>", mode = "v", desc = "Link" },
			{ prefix .. "l", "<cmd>Obsidian links<CR>", desc = "Links" },
			{ prefix .. "l", "<cmd>Obsidian link_new<CR>", mode = "v", desc = "New Link" },
			{ prefix .. "e", "<cmd>Obsidian extract_note<CR>", mode = "v", desc = "Extract Note" },
			{ prefix .. "w", "<cmd>Obsidian workspace<CR>", desc = "Workspace" },
			{ prefix .. "r", "<cmd>Obsidian rename<CR>", desc = "Rename" },
			{ prefix .. "i", "<cmd>Obsidian paste_img<CR>", desc = "Paste Image" },
			{ prefix .. "p", "<cmd>MarkdownPreview<CR>", desc = "Preview File" },
			{ prefix .. "D", "<cmd>Obsidian today<CR>", desc = "Daily Note" },
		},

    opts = {
				legacy_commands = false,

				workspaces = {
					{ name = "notes", path = "/mnt/Storage/Documents/notes/" },
					{ name = "notes", path = "~/Documents/notes" },
				},

				callbacks = {
					enter_note = function(note)
						local api = require("obsidian.api")

						vim.keymap.set("n", "<leader>ch", function()
							require("obsidian.api").toggle_checkbox()
						end, { buffer = note.bufnr, desc = "Toggle checkbox" })

						-- -- link navigation
						-- vim.keymap.set("n", "<leader>on", function()
						-- 	api.nav_link("next")
						-- end, {
						-- 	buffer = note.bufnr,
						-- 	desc = "Next link",
						-- })
						-- vim.keymap.set("n", "<leader>oN", function()
						-- 	api.nav_link("prev")
						-- end, {
						-- 	buffer = note.bufnr,
						-- 	desc = "Previous link",
						-- })
					end,
				},

				notes_subdir = "000 Index",
				new_notes_location = "notes_subdir",

				ui = {
					enable = false,
				},

				frontmatter = {
					enabled = true,
					sort = { "aliases", "tags", "references", "links" },
					func = function(note)
						-- Only keep aliases that already exist in the note's frontmatter.
						-- For new notes, this will be an empty YAML list: aliases: []
						local meta = note.metadata or {}
						local aliases = meta.aliases or {} -- <- do NOT use note.aliases

						return {
							aliases = aliases,
							tags = note.tags,
							references = meta.references or {},
							links = meta.links or {},
						}
					end,
				},
				note_id_func = function(title)
					return title
				end,

				picker = {
					name = "snacks.pick",
					note_mappings = { new = "<C-x>", insert_link = "<C-l>" },
					tag_mappings = { tag_note = "<C-x>", insert_tag = "<C-l>" },
				},

				templates = {
					folder = "000 Index/001 Templates/",
					date_format = "%Y-%m-%d",
					time_format = "%H:%M",
					substitutions = {
						yday = function()
							local fmt = "%Y-%m-%d"
							return os.date(fmt, os.time() - 24 * 60 * 60)
						end,
						tmrw = function()
							local fmt = "%Y-%m-%d"
							return os.date(fmt, os.time() + 24 * 60 * 60)
						end,
						week_id = function()
							-- ISO week, e.g. "2025-W11"
							local fmt = "%G-W%V"
							return os.date(fmt)
						end,
					},
				},

				daily_notes = {
					folder = "300 Personal/Daily",
					date_format = "%Y-%m-%d",
					default_tags = { "daily" },
					template = "Daily NVIM",
				},

				attachments = {
					folder = "999 Images/",
					img_text_func = function(path)
						return string.format("![[%s]]", path.name)
					end,
				},

				checkbox = {
					enabled = true,
					create_new = true,
					order = { " ", "x", "!", ">", "~" },
				},

				search = {
					sort_by = "modified",
					sort_reversed = true,
				},

				footer = { enabled = false },
			}
	},
}
