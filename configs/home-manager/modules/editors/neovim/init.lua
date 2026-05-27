vim.loader.enable()

local nix_info = require("config.nix")
local stylix_cache_key = nix_info.get("default", "info", "stylix", "cacheKey")

vim.g.base46_cache = vim.fn.stdpath("cache") .. "/base46_cache/" .. stylix_cache_key .. "/"
vim.fn.mkdir(vim.g.base46_cache, "p")

-- Must be set before plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true

-- Core config
require("config.options")
require("config.autocmds")
require("config.keymaps")

local lzextras = require("lzextras")
vim.g.lze = vim.g.lze or {}
vim.g.lze.load = lzextras.loaders.with_after

require("lze").load(lzextras.mod_dir_to_spec("plugins"))

for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
	dofile(vim.g.base46_cache .. v)
end
