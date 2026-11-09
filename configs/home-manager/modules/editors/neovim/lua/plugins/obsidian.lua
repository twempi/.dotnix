local prefix = "<leader>o"
local daily_folder = "300 Personal/Daily"

-- Dates follow the note being created, so `:Obsidian tomorrow` doesn't get today's links.
local function note_time(ctx, offset_days)
	local id = ctx.partial_note and ctx.partial_note.id or ""
	local year, month, day = string.match(id, "^(%d%d%d%d)-(%d%d)-(%d%d)$")
	if not year then
		return os.time() + offset_days * 24 * 60 * 60
	end
	-- Noon keeps a daylight saving shift from moving the date.
	return os.time({ year = year, month = month, day = day + offset_days, hour = 12 })
end

-- Port of the to-do rollover in the vault's "Daily Notes" Templater template.
local function rollover_todos(ctx)
	local empty = "- [ ] "
	local path = ctx.partial_note and ctx.partial_note.path
	if not path then
		return empty
	end

	local dir, target = vim.fs.dirname(tostring(path)), vim.fs.basename(tostring(path))
	local previous
	for name in vim.fs.dir(dir) do
		if name:match("^%d%d%d%d%-%d%d%-%d%d%.md$") and name < target and (not previous or name > previous) then
			previous = name
		end
	end
	if not previous then
		return empty
	end

	local todos, in_section = {}, false
	for raw in io.lines(dir .. "/" .. previous) do
		local line = raw:gsub("\r$", "")
		if line:match("^## To Do's") then
			in_section = true
		elseif in_section and line:match("^## ") then
			break
		elseif in_section and line:match("^%s*[-*+] %[ %] %s*%S") then
			todos[#todos + 1] = line
		end
	end
	return #todos > 0 and table.concat(todos, "\n") or empty
end

-- gf can't create files, so a link to a daily note that doesn't exist yet would fail with E447.
local function goto_daily_or_file()
	local link = require("obsidian.api").cursor_link()
	local ref = link and require("obsidian.parse.refs").parse(link)
	local id = ref and ref.target and ref.target:gsub("^" .. vim.pesc(daily_folder) .. "/", "")
	if not (id and id:match("^%d%d%d%d%-%d%d%-%d%d$")) then
		vim.api.nvim_feedkeys("gf", "n", false)
		return
	end

	local note = require("obsidian.daily").daily({ date = note_time({ partial_note = { id = id } }, 0) })
	if not note:exists() then
		note:write()
	end
	note:open()
end

return {
	{
		"obsidian.nvim",
		ft = { "markdown" },
		cmd = "Obsidian",

		keys = {
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
						vim.keymap.set("n", "gf", goto_daily_or_file, { buffer = note.bufnr, desc = "Go to file or daily note" })
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

				-- Managing frontmatter rewrites it on every save: bare notes gain tags, keys reorder, YAML comments vanish.
				frontmatter = { enabled = false },

				note = { template = "Normal Note.md" },

				note_id_func = function(title)
					return title or "Untitled"
				end,

				picker = {
					name = "snacks.picker",
					note_mappings = { new = "<C-x>", insert_link = "<C-l>" },
					tag_mappings = { tag_note = "<C-x>", insert_tag = "<C-l>" },
				},

				templates = {
					enabled = true,
					folder = "999 Templates",
					date_format = "%Y-%m-%d",
					time_format = "%H:%M",
					substitutions = {
						yday = function(ctx)
							return os.date("%Y-%m-%d", note_time(ctx, -1)) --[[@as string]]
						end,
						tmrw = function(ctx)
							return os.date("%Y-%m-%d", note_time(ctx, 1)) --[[@as string]]
						end,
						week_id = function(ctx)
							return os.date("%G-W%V", note_time(ctx, 0)) --[[@as string]]
						end,
						rollover = rollover_todos,
					},
				},

				daily_notes = {
					folder = daily_folder,
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
					order = { " ", "x" },
				},

				-- Upstream types mark max_lines required, but setup merges in the default.
				---@diagnostic disable-next-line: missing-fields
				search = {
					sort_by = "modified",
					sort_reversed = true,
				},

				footer = { enabled = false },
			})
		end,
	},
}
