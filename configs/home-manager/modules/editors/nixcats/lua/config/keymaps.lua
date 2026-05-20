-- [[ Non-plugin keymaps ]]

local map = vim.keymap.set

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

-- netrw tweaks
vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0
