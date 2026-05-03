-- put this in your main init.lua file ( before lazy setup )
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"
vim.fn.mkdir(vim.g.base46_cache, "p")  -- ensure directory exists

require("nixCatsUtils").setup({
  non_nix_value = true,
})

-- Must be set before plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true

-- Core config
require("config.options")
require("config.autocmds")
require("config.keymaps")

-- nixCats + lazy.nvim wrapper
local nixCats = require("nixCats")

local lazy_spec = {
  { import = "plugins" },
}

require("nixCatsUtils.lazyCat").setup(
  nixCats.pawsible({ "allPlugins", "start", "lazy.nvim" }),
  lazy_spec,
  {
    defaults = { lazy = true },
    ui = { border = "rounded" },
    checker = { enabled = false },
  }
)

-- after lazy setup: load cached base46 highlights
-- (method 1 from nvchad/ui docs)
-- dofile(vim.g.base46_cache .. "defaults")
-- dofile(vim.g.base46_cache .. "statusline")

-- if you prefer your old "load everything" method, you can do:
for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
  dofile(vim.g.base46_cache .. v)
end

