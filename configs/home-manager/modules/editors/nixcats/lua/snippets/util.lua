local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local raw_fmt = require("luasnip.extras.fmt").fmt

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local M = {}

local function fmt(...)
	local split = vim.split
	vim.split = function(str, sep, opts)
		if type(opts) == "boolean" then
			opts = { trimempty = opts }
		end

		return split(str, sep, opts)
	end

	local ok, result = pcall(raw_fmt, ...)
	vim.split = split

	if not ok then
		error(result)
	end

	return result
end

local function count_inline_dollars(str)
	local count = 0
	for idx = 1, #str do
		local char = str:sub(idx, idx)
		local prev = str:sub(idx - 1, idx - 1)
		local next = str:sub(idx + 1, idx + 1)
		if char == "$" and prev ~= "\\" and prev ~= "$" and next ~= "$" then
			count = count + 1
		end
	end
	return count
end

local function in_dollar_block()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, 0, row, true)
	local fences = 0

	for _, line in ipairs(lines) do
		if line:match("^%s*%$%$%s*$") or line:match("^%s*%$%s*$") then
			fences = fences + 1
		end
	end

	return fences % 2 == 1
end

function M.in_math()
	local ft = vim.bo.filetype

	if ft == "tex" or ft == "plaintex" or ft == "latex" then
		if vim.fn.exists("*vimtex#syntax#in_mathzone") == 1 then
			return vim.fn["vimtex#syntax#in_mathzone"]() == 1
		end
		return true
	end

	if ft == "markdown" or ft == "typst" then
		local col = vim.api.nvim_win_get_cursor(0)[2]
		local before = vim.api.nvim_get_current_line():sub(1, col)
		return count_inline_dollars(before) % 2 == 1 or in_dollar_block()
	end

	return false
end

function M.not_math()
	return not M.in_math()
end

function M.at_line_start(line_to_cursor)
	return line_to_cursor:match("^%s*[%w_%-]+$") ~= nil
end

local function all(...)
	local conditions = { ... }
	return function(...)
		for _, condition in ipairs(conditions) do
			if not condition(...) then
				return false
			end
		end
		return true
	end
end

local function autosnippet(trig, nodes, opts)
	opts = opts or {}
	local context = vim.tbl_extend("force", {
		trig = trig,
		snippetType = "autosnippet",
		wordTrig = opts.wordTrig == true,
	}, opts.context or {})

	if opts.name then
		context.name = opts.name
	end
	if opts.dscr then
		context.dscr = opts.dscr
	end

	return s(context, nodes, opts.condition and { condition = opts.condition } or nil)
end

local function snippet(trig, nodes, opts)
	opts = opts or {}
	return s(
		{ trig = trig, name = opts.name, dscr = opts.dscr },
		nodes,
		opts.condition and { condition = opts.condition } or nil
	)
end

local function math_auto(trig, nodes, opts)
	opts = opts or {}
	opts.condition = opts.condition or M.in_math
	return autosnippet(trig, nodes, opts)
end

local function word_math_auto(trig, nodes, opts)
	opts = opts or {}
	opts.wordTrig = true
	return math_auto(trig, nodes, opts)
end

local function line_start_auto(trig, nodes, opts)
	opts = opts or {}
	opts.wordTrig = true
	opts.condition = opts.condition or all(M.not_math, M.at_line_start)
	return autosnippet(trig, nodes, opts)
end

local latex_greek = {
	["@a"] = "\\alpha",
	["@b"] = "\\beta",
	["@g"] = "\\gamma",
	["@G"] = "\\Gamma",
	["@d"] = "\\delta",
	["@D"] = "\\Delta",
	["@e"] = "\\epsilon",
	[":e"] = "\\varepsilon",
	["@t"] = "\\theta",
	["@T"] = "\\Theta",
	["@l"] = "\\lambda",
	["@L"] = "\\Lambda",
	["@s"] = "\\sigma",
	["@S"] = "\\Sigma",
	["@o"] = "\\omega",
	["@O"] = "\\Omega",
}

local typst_greek = {
	["@a"] = "alpha",
	["@b"] = "beta",
	["@g"] = "gamma",
	["@G"] = "Gamma",
	["@d"] = "delta",
	["@D"] = "Delta",
	["@e"] = "epsilon",
	[":e"] = "epsilon.alt",
	["@t"] = "theta",
	["@T"] = "Theta",
	["@l"] = "lambda",
	["@L"] = "Lambda",
	["@s"] = "sigma",
	["@S"] = "Sigma",
	["@o"] = "omega",
	["@O"] = "Omega",
}

local function latex_math_autos()
	local autos = {
		math_auto("sr", t("^{2}")),
		math_auto("cb", t("^{3}")),
		word_math_auto("rd", fmt("^{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("sub", fmt("_{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("sq", fmt("\\sqrt{ <> }<>", { i(1), i(0) }, { delimiters = "<>" })),
		math_auto("//", fmt("\\frac{<>}{<>}<>", { i(1), i(2), i(0) }, { delimiters = "<>" })),
		word_math_auto(
			"lim",
			fmt("\\lim_{ <> \\to <> } <>", { i(1, "n"), i(2, "\\infty"), i(0) }, { delimiters = "<>" })
		),
		word_math_auto("sum", fmt("\\sum_{<>}^{<>} <>", { i(1, "i=1"), i(2, "n"), i(0) }, { delimiters = "<>" })),
		word_math_auto("prod", fmt("\\prod_{<>}^{<>} <>", { i(1, "i=1"), i(2, "n"), i(0) }, { delimiters = "<>" })),
		word_math_auto("int", fmt("\\int <> \\, d<> <>", { i(1), i(2, "x"), i(0) }, { delimiters = "<>" })),
		word_math_auto(
			"dint",
			fmt("\\int_{<>}^{<>} <> \\, d<> <>", { i(1, "0"), i(2, "1"), i(3), i(4, "x"), i(0) }, { delimiters = "<>" })
		),
		word_math_auto(
			"par",
			fmt("\\frac{\\partial <>}{\\partial <>} <>", { i(1, "y"), i(2, "x"), i(0) }, { delimiters = "<>" })
		),

		word_math_auto("ooo", t("\\infty")),
		math_auto("xx", t("\\times")),
		math_auto("+-", t("\\pm")),
		math_auto("!=", t("\\neq")),
		math_auto(">=", t("\\geq")),
		math_auto("<=", t("\\leq")),
		math_auto("->", t("\\to")),
		math_auto("<-", t("\\leftarrow")),
		math_auto("<->", t("\\leftrightarrow")),
		math_auto("=>", t("\\implies")),
		word_math_auto("inn", t("\\in")),
		word_math_auto("notin", t("\\notin")),
		word_math_auto("sub=", t("\\subseteq")),
		word_math_auto("sup=", t("\\supseteq")),
		word_math_auto("RR", t("\\mathbb{R}")),
		word_math_auto("NN", t("\\mathbb{N}")),
		word_math_auto("ZZ", t("\\mathbb{Z}")),
		word_math_auto("QQ", t("\\mathbb{Q}")),
		word_math_auto("CC", t("\\mathbb{C}")),

		word_math_auto("hat", fmt("\\hat{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("bar", fmt("\\bar{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("vec", fmt("\\vec{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("dot", fmt("\\dot{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("ddot", fmt("\\ddot{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("bf", fmt("\\mathbf{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("rm", fmt("\\mathrm{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("text", fmt("\\text{<>}<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("beg", fmt("\\begin{<>}\n\t<>\n\\end{<>}", { i(1), i(2), rep(1) }, { delimiters = "<>" })),
		word_math_auto("pmat", fmt("\\begin{pmatrix}\n\t<>\n\\end{pmatrix}", { i(0) }, { delimiters = "<>" })),
		word_math_auto("bmat", fmt("\\begin{bmatrix}\n\t<>\n\\end{bmatrix}", { i(0) }, { delimiters = "<>" })),
		word_math_auto("case", fmt("\\begin{cases}\n\t<>\n\\end{cases}", { i(0) }, { delimiters = "<>" })),
		word_math_auto("align", fmt("\\begin{aligned}\n\t<>\n\\end{aligned}", { i(0) }, { delimiters = "<>" })),
	}

	for trig, replacement in pairs(latex_greek) do
		table.insert(autos, math_auto(trig, t(replacement)))
	end

	return autos
end

local function typst_math_autos()
	local autos = {
		math_auto("sr", t("^2")),
		math_auto("cb", t("^3")),
		word_math_auto("rd", fmt("^(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("sub", fmt("_(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("sq", fmt("sqrt(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		math_auto("//", fmt("frac(<>, <>)<>", { i(1), i(2), i(0) }, { delimiters = "<>" })),
		word_math_auto(
			"lim",
			fmt("lim_(<> arrow.r <>) <>", { i(1, "n"), i(2, "infinity"), i(0) }, { delimiters = "<>" })
		),
		word_math_auto("sum", fmt("sum_(<>)^(<>) <>", { i(1, "i=1"), i(2, "n"), i(0) }, { delimiters = "<>" })),
		word_math_auto("prod", fmt("product_(<>)^(<>) <>", { i(1, "i=1"), i(2, "n"), i(0) }, { delimiters = "<>" })),
		word_math_auto("int", fmt("integral <> dif <> <>", { i(1), i(2, "x"), i(0) }, { delimiters = "<>" })),
		word_math_auto(
			"dint",
			fmt(
				"integral_(<>)^(<>) <> dif <> <>",
				{ i(1, "0"), i(2, "1"), i(3), i(4, "x"), i(0) },
				{ delimiters = "<>" }
			)
		),
		word_math_auto("par", fmt("diff(<>, <>)<>", { i(1, "y"), i(2, "x"), i(0) }, { delimiters = "<>" })),

		word_math_auto("ooo", t("infinity")),
		math_auto("xx", t("times")),
		math_auto("+-", t("plus.minus")),
		math_auto("!=", t("eq.not")),
		math_auto(">=", t("gt.eq")),
		math_auto("<=", t("lt.eq")),
		math_auto("->", t("arrow.r")),
		math_auto("<-", t("arrow.l")),
		math_auto("<->", t("arrow.l.r")),
		math_auto("=>", t("arrow.r.double")),
		word_math_auto("inn", t("in")),
		word_math_auto("notin", t("in.not")),
		word_math_auto("sub=", t("subset.eq")),
		word_math_auto("sup=", t("supset.eq")),
		word_math_auto("RR", t("bb(R)")),
		word_math_auto("NN", t("bb(N)")),
		word_math_auto("ZZ", t("bb(Z)")),
		word_math_auto("QQ", t("bb(Q)")),
		word_math_auto("CC", t("bb(C)")),

		word_math_auto("hat", fmt("hat(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("bar", fmt("macron(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("vec", fmt("arrow(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("dot", fmt("dot(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("ddot", fmt("dot.double(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("bf", fmt("bold(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("rm", fmt("upright(<>)<>", { i(1), i(0) }, { delimiters = "<>" })),
		word_math_auto("text", fmt('"<>"<>', { i(1), i(0) }, { delimiters = "<>" })),
	}

	for trig, replacement in pairs(typst_greek) do
		table.insert(autos, math_auto(trig, t(replacement)))
	end

	return autos
end

function M.latex()
	local snippets = {
		snippet("mk", fmt("$<>$<>", { i(1), i(0) }, { delimiters = "<>" })),
		snippet("dm", fmt("\\[\n\t<>\n\\]\n<>", { i(1), i(0) }, { delimiters = "<>" })),
	}

	return snippets, latex_math_autos()
end

function M.markdown()
	local snippets = {
		snippet("mk", fmt("$<>$<>", { i(1), i(0) }, { delimiters = "<>" })),
		snippet("dm", fmt("$$\n\t<>\n$$\n<>", { i(1), i(0) }, { delimiters = "<>" })),
		snippet("code", fmt("```<>\n<>\n```\n<>", { i(1), i(2), i(0) }, { delimiters = "<>" })),
	}

	local autos = latex_math_autos()
	vim.list_extend(autos, {
		line_start_auto("todo", fmt("- [ ] <>", { i(0) }, { delimiters = "<>" })),
		line_start_auto("cmd", fmt("`<>`<>", { i(1), i(0) }, { delimiters = "<>" })),
		line_start_auto("sh", fmt("```sh\n<>\n```\n<>", { i(1), i(0) }, { delimiters = "<>" })),
		line_start_auto("lua", fmt("```lua\n<>\n```\n<>", { i(1), i(0) }, { delimiters = "<>" })),
		line_start_auto("nix", fmt("```nix\n<>\n```\n<>", { i(1), i(0) }, { delimiters = "<>" })),
		line_start_auto("py", fmt("```python\n<>\n```\n<>", { i(1), i(0) }, { delimiters = "<>" })),
		line_start_auto("typ", fmt("```typst\n<>\n```\n<>", { i(1), i(0) }, { delimiters = "<>" })),
		line_start_auto(
			"codenote",
			fmt(
				"## Context\n- <>\n\n## Code\n```<>\n<>\n```\n\n## Notes\n- <>",
				{ i(1), i(2, "text"), i(3), i(0) },
				{ delimiters = "<>" }
			)
		),
		line_start_auto(
			"bugnote",
			fmt(
				"## Symptom\n- <>\n\n## Cause\n- <>\n\n## Fix\n- <>\n\n## Verification\n- <>",
				{ i(1), i(2), i(3), i(0) },
				{ delimiters = "<>" }
			)
		),
		line_start_auto(
			"apinote",
			fmt(
				"## Endpoint\n`<> <>`\n\n## Request\n```json\n<>\n```\n\n## Response\n```json\n<>\n```",
				{ i(1, "GET"), i(2, "/path"), i(3), i(0) },
				{ delimiters = "<>" }
			)
		),
	})

	return snippets, autos
end

function M.typst()
	local snippets = {
		snippet("mk", fmt("$<>$<>", { i(1), i(0) }, { delimiters = "<>" })),
		snippet("dm", fmt("$\n\t<>\n$\n<>", { i(1), i(0) }, { delimiters = "<>" })),
	}

	return snippets, typst_math_autos()
end

return M
