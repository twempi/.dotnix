local M = {}

local nix_info = require("config.nix")
local raw_colors = nix_info.get({}, "info", "stylix", "colors")
local colors = type(raw_colors) == "table" and raw_colors or {}
local polarity = nix_info.get("dark", "info", "stylix", "polarity")
local lighten = require("base46.colors").change_hex_lightness

local function color(name, fallback)
	return colors[name] or fallback
end

local base00 = color("base00", "#000000")
local base01 = color("base01", "#111111")
local base02 = color("base02", "#222222")
local base03 = color("base03", "#444444")
local base04 = color("base04", "#888888")
local base05 = color("base05", "#cccccc")
local base06 = color("base06", "#dddddd")
local base07 = color("base07", "#ffffff")
local base08 = color("base08", "#ff5555")
local base09 = color("base09", "#ff9955")
local base0A = color("base0A", "#ffff55")
local base0B = color("base0B", "#55ff55")
local base0C = color("base0C", "#55ffff")
local base0D = color("base0D", "#5599ff")
local base0E = color("base0E", "#aa55ff")
local base0F = color("base0F", "#ff55aa")

M.base_30 = {
	white = base07,
	black = base00,
	darker_black = lighten(base00, -3),
	black2 = base01,
	one_bg = base01,
	one_bg2 = base02,
	one_bg3 = base03,
	grey = base03,
	grey_fg = base04,
	grey_fg2 = lighten(base04, -8),
	light_grey = base04,
	red = base08,
	baby_pink = lighten(base08, 10),
	pink = base0F,
	line = base02,
	green = base0B,
	vibrant_green = lighten(base0B, 10),
	blue = base0D,
	nord_blue = lighten(base0D, 10),
	yellow = base0A,
	sun = lighten(base0A, 10),
	purple = base0E,
	dark_purple = lighten(base0E, -10),
	teal = base0C,
	orange = base09,
	cyan = base0C,
	statusline_bg = base01,
	lightbg = base02,
	pmenu_bg = base0D,
	folder_bg = base0D,
	lavender = base0E,
}

M.base_16 = {
	base00 = base00,
	base01 = base01,
	base02 = base02,
	base03 = base03,
	base04 = base04,
	base05 = base05,
	base06 = base06,
	base07 = base07,
	base08 = base08,
	base09 = base09,
	base0A = base0A,
	base0B = base0B,
	base0C = base0C,
	base0D = base0D,
	base0E = base0E,
	base0F = base0F,
}

M.type = polarity == "light" and "light" or "dark"

M.polish_hl = {
	defaults = {
		Comment = {
			italic = true,
			fg = M.base_16.base03,
		},
	},
	Syntax = {
		String = {
			fg = M.base_16.base0B,
		},
	},
	treesitter = {
		["@comment"] = {
			fg = M.base_16.base03,
		},
		["@string"] = {
			fg = M.base_16.base0B,
		},
		["@variable.builtin"] = {
			fg = M.base_16.base08,
		},
		["@property"] = {
			fg = M.base_16.base0C,
		},
	},
}

M = require("base46").override_theme(M, "stylix")

return M
