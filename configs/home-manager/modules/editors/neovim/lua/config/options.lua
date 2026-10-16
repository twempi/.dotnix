-- [[ Options ]]
vim.opt.list = true

vim.g.snacks_animate = true
vim.g.markdown_recommended_style = 0

vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.opt.inccommand = "split"
vim.opt.scrolloff = 10
vim.opt.confirm = true
vim.opt.linebreak = true

vim.opt.swapfile = false

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.mouse = "a"
vim.opt.cpoptions:append("I")
vim.opt.expandtab = true
vim.opt.cursorline = true

-- Locally Neovim auto-detects wl-clipboard/xclip. Over SSH, copy via OSC 52 so
-- the local terminal sets its clipboard; paste with the terminal's own paste.
if vim.env.SSH_TTY then
	local osc52 = require("vim.ui.clipboard.osc52")
	local function paste_register()
		return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
	end
	vim.g.clipboard = {
		name = "osc52-copy",
		copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
		paste = { ["+"] = paste_register, ["*"] = paste_register },
	}
end

vim.opt.clipboard = "unnamedplus"

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.smoothscroll = true
vim.opt.spell = true
vim.opt.spelllang = { "en_us" }
vim.opt.spellsuggest = { "best", 9 }
vim.opt.signcolumn = "yes"

vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
