local prefix = "<leader>o"

return {
	{
		"obsidian.nvim",
		ft = { "markdown" },

		keys = {
			{ prefix, "<Nop>", desc = "[o]bsidian" },
			{ prefix .. "o", "<cmd>Obsidian open<CR>", desc = "Open on App" },
			{ prefix .. "g", "<cmd>Obsidian search<CR>", desc = "Grep" },
			{ prefix .. "n", "<cmd>Obsidian new<CR>", desc = "New Note" },
			{ prefix .. "N", "<cmd>Obsidian new_from_template<CR>", desc = "New Note (Template)" },
			{ prefix .. "<space>", "<cmd>Obsidian quick_switch<CR>", desc = "Find Files" },
			{ prefix .. "b", "<cmd>Obsidian backlinks<CR>", desc = "Backlinks" },
			{ prefix .. "ch", "<Nop>", desc = "Toggle checkbox" },
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

		after = function()
			require("obsidian").setup({
			legacy_commands = false,

			workspaces = {
				{ name = "notes", path = "~/Documents/notes" },
			},

			callbacks = {
				enter_note = function(note)
					vim.keymap.set("n", prefix .. "ch", function()
						require("obsidian.api").toggle_checkbox()
					end, { buffer = note.bufnr, desc = "Toggle checkbox" })
				end,
			},

			notes_subdir = "000 Home/Inbox",
			new_notes_location = "notes_subdir",

			ui = {
				enable = false,
			},

			link = {
				style = "wiki",
				format = "shortest",
				auto_update = true,
			},

			frontmatter = {
				enabled = true,
				sort = { "tags", "type", "course", "topic", "references", "urls" },
				func = function(note)
					local meta = vim.deepcopy(note.metadata or {})
					meta.tags = note.tags or {}
					return meta
				end,
			},

			note_id_func = function(title)
				return title or "Untitled"
			end,

			picker = {
				name = "snacks.pick",
				note_mappings = { new = "<C-x>", insert_link = "<C-l>" },
				tag_mappings = { tag_note = "<C-x>", insert_tag = "<C-l>" },
			},

			templates = {
				enabled = true,
				folder = "999 Templates",
				date_format = "%Y-%m-%d",
				time_format = "%H:%M",
				substitutions = {
					yday = function()
						return os.date("%Y-%m-%d", os.time() - 24 * 60 * 60)
					end,
					tmrw = function()
						return os.date("%Y-%m-%d", os.time() + 24 * 60 * 60)
					end,
					week_id = function()
						return os.date("%G-W%V")
					end,
				},
			},

			daily_notes = {
				folder = "300 Personal/Daily",
				date_format = "%Y-%m-%d",
				default_tags = { "daily" },
				template = "Daily NVIM.md",
				workdays_only = false,
			},

			attachments = {
				folder = "990 Attachments",
				img_name_func = function()
					return string.format("Pasted image %s", os.date("%Y%m%d%H%M%S"))
				end,
				img_text_func = function(path)
					return string.format("![[%s]]", path.name)
				end,
				confirm_img_paste = false,
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
			})
		end,
	},
}
