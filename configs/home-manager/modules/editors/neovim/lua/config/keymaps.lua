-- [[ Non-plugin keymaps ]]

local map = vim.keymap.set

-- netrw tweaks
vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0

-- Moving lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Soft-wrap friendly movement
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Better indenting
map("x", "<", "<gv", { desc = "Indent left" })
map("x", ">", ">gv", { desc = "Indent right" })

-- Scrolling and search navigation
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up" })
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Prev search result" })

-- Buffers
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprev<CR>", { desc = "Previous buffer" })
map("n", "<leader>bl", "<cmd>b#<CR>", { desc = "Last buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

local diagnostic_goto = function(next)
	return function()
		if vim.diagnostic.jump then
			vim.diagnostic.jump({ count = next and 1 or -1, float = true })
		elseif next then
			vim.diagnostic.goto_next({ float = true })
		else
			vim.diagnostic.goto_prev({ float = true })
		end
	end
end

-- Diagnostics and lists
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "[d", diagnostic_goto(false), { desc = "Previous diagnostic" })
map("n", "]d", diagnostic_goto(true), { desc = "Next diagnostic" })

-- Panel Navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

-- Resize windows
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- C: compile and run the current file in the tmux pane right of Neovim
local function shell_quote(s)
	-- Outside the quotes, \' and \\ mean the same thing to fish and POSIX shells.
	return "'" .. s:gsub("[\\']", { ["\\"] = "'\\\\'", ["'"] = "'\\''" }) .. "'"
end

local function tmux(args)
	local result = vim.system(vim.list_extend({ "tmux" }, args), { text = true }):wait()
	return result.code == 0 and vim.trim(result.stdout) or nil
end

local function c_run_in_tmux()
	local function warn(msg)
		vim.notify(msg, vim.log.levels.WARN)
	end

	local file = vim.api.nvim_buf_get_name(0)
	if vim.bo.buftype ~= "" or not file:match("%.c$") then
		return warn("Not a named .c file")
	end
	-- Declining the "file changed since reading it" prompt leaves the buffer modified, without an error.
	vim.cmd.update()
	if vim.bo.modified then
		return warn("File not saved; nothing sent to tmux")
	end

	local nvim_pane = vim.env.TMUX and vim.env.TMUX_PANE
	if not nvim_pane then
		return warn("Neovim is not running inside tmux")
	elseif vim.fn.executable("tmux") == 0 then
		return warn("tmux is not on PATH")
	end

	-- {right-of} falls back to Neovim's own pane, or wraps around to the left edge.
	local nvim_info = tmux({ "display-message", "-p", "-t", nvim_pane, "#{window_id} #{pane_right}" }) or ""
	local window, nvim_right = nvim_info:match("^(%S+) (%d+)$")
	local format = "#{pane_id} #{pane_left} #{pane_in_mode} #{bracket_paste_flag} #{pane_current_command}"
	local info = window and tmux({ "display-message", "-p", "-t", window .. ".{right-of}", format }) or ""
	local pane, left, in_mode, at_prompt, command = info:match("^(%S+) (%d+) (%d+) (%d) (.*)$")
	if not pane or pane == nvim_pane or tonumber(left) <= tonumber(nvim_right) then
		return warn("No tmux pane to the right of Neovim")
	elseif in_mode ~= "0" then
		return warn("The right tmux pane is in copy mode")
	-- Shells turn on bracketed paste only while their prompt waits for input.
	elseif not ({ bash = true, fish = true, sh = true, zsh = true })[command] or at_prompt ~= "1" then
		return warn("The right tmux pane is busy: " .. command)
	end

	local exe = ("%s/c-run/%s-%s"):format(
		vim.fn.stdpath("cache"),
		vim.fn.fnamemodify(file, ":t:r"),
		vim.fn.sha256(file):sub(1, 8)
	)
	vim.fn.mkdir(vim.fs.dirname(exe), "p")
	local cmd = ("cd %s && cc -std=c17 -Wall -Wextra -g %s -o %s && %s"):format(
		shell_quote(vim.fs.dirname(file)),
		shell_quote(vim.fs.basename(file)),
		shell_quote(exe),
		shell_quote(exe)
	)

	-- C-u C-k clears a half-typed line in order (C-c is a signal and can race the paste).
	-- The command is pasted, not typed: fish's vi normal mode would run typed keys as commands.
	tmux({ "send-keys", "-t", pane, "C-u", "C-k" })
	tmux({ "set-buffer", "-b", "c-run", cmd })
	tmux({ "paste-buffer", "-b", "c-run", "-d", "-p", "-t", pane })
	tmux({ "send-keys", "-t", pane, "Enter" })
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "c",
	callback = function(event)
		map("n", ",,", c_run_in_tmux, { buffer = event.buf, desc = "Compile and run in right tmux pane" })
	end,
})
