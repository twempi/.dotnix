-- [[ Options ]]
vim.opt.list = true
-- vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.g.snacks_animate = true
vim.g.markdown_recommended_style = 0

vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')


vim.opt.inccommand = 'split'
vim.opt.scrolloff = 10
vim.opt.confirm = true
vim.opt.linebreak = true

vim.opt.swapfile = false

vim.opt.number = true
vim.opt.relativenumber = true


vim.opt.mouse = 'a'
vim.opt.cpoptions:append('I')
vim.opt.expandtab = true
vim.opt.cursorline = true

vim.opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
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
vim.opt.spelllang = {"en"}
vim.opt.spellsuggest = { "best", 9 }
vim.opt.signcolumn = 'yes'


vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = { "menu", "menuone", "noselect" }


-- Colorscheme (set early so UIs can pick it up)
-- vim.cmd.colorscheme('nvchad')
