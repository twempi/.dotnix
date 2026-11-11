-- Port of the Obsidian Latex Suite snippets in
-- ~/Documents/notes/.obsidian/plugins/obsidian-latex-suite/data.json.
-- Entries keep Latex Suite's format so the two can be compared side by side:
--   options:     t text, m math, M display math, n inline math,
--                A automatic, r regex, w word boundary
--   replacement: $0 $1 ${0:default} tabstops, [[0]] regex captures,
--                ${VISUAL} the selection stored with <Tab> in visual mode
-- Regex literals from data.json are written as [[...]] with an "r" added.

local ls = require("luasnip")
local s, sn, t, i, d = ls.snippet, ls.snippet_node, ls.text_node, ls.insert_node, ls.dynamic_node
local rep = require("luasnip.extras").rep

local variables = {
	["${GREEK}"] = "(?:alpha|beta|gamma|Gamma|delta|Delta|epsilon|varepsilon|zeta|eta|theta|vartheta|Theta|iota|kappa|lambda|Lambda|mu|nu|xi|omicron|pi|rho|varrho|sigma|Sigma|tau|upsilon|Upsilon|phi|varphi|Phi|chi|psi|omega|Omega)",
	["${SYMBOL}"] = "(?:parallel|perp|partial|nabla|hbar|ell|infty|oplus|ominus|otimes|oslash|square|star|dagger|vee|wedge|subseteq|subset|supseteq|supset|emptyset|exists|nexists|forall|implies|impliedby|iff|setminus|neg|lor|land|bigcup|bigcap|cdot|times|simeq|approx)",
	["${MORE_SYMBOLS}"] = "(?:leq|geq|neq|gg|ll|equiv|sim|propto|rightarrow|leftarrow|Rightarrow|Leftarrow|leftrightarrow|to|mapsto|cap|cup|in|sum|prod|exp|ln|log|det|dots|vdots|ddots|pm|mp|int|iint|iiint|oint)",
	["${ACCENT}"] = "(?:dot|ddot|hat|bar|tilde|vec|underline|overline|mathbf|mathcal|mathrm|mathbb)",
}

-- Latex Suite's wordDelimiters setting.
local delimiters = "., +-\n\t:;!?\\/{}[]()=~$'\"|`<>*^%#@&"

local defs = {
	-- Math mode
	{ "mk", "$$0$", "tA" },
	{ "dm", "$$\n\t$0\n$$", "tAw" },
	{ [[(?<=\S.*)dm]], "\n$$\n\t$0\n$$", "rtAw", priority = 1 },

	{ [[([^\\])beg]], "[[0]]\\begin{$0}\n\t$1\n\\end{$0}", "rMA" },
	{ [[([^\\])beg]], "[[0]]\\begin{$0} $1 \\end{$0}", "rnA" },

	-- Greek letters
	{ "@a", "\\alpha", "mA" },
	{ "@b", "\\beta", "mA" },
	{ "@g", "\\gamma", "mA" },
	{ "@G", "\\Gamma", "mA" },
	{ "@d", "\\delta", "mA" },
	{ "@D", "\\Delta", "mA" },
	{ "@e", "\\epsilon", "mA" },
	{ ":e", "\\varepsilon", "mA" },
	{ "@z", "\\zeta", "mA" },
	{ "@t", "\\theta", "mA" },
	{ "@T", "\\Theta", "mA" },
	{ ":t", "\\vartheta", "mA" },
	{ "@i", "\\iota", "mA" },
	{ "@k", "\\kappa", "mA" },
	{ "@l", "\\lambda", "mA" },
	{ "@L", "\\Lambda", "mA" },
	{ "@s", "\\sigma", "mA" },
	{ "@S", "\\Sigma", "mA" },
	{ "@u", "\\upsilon", "mA" },
	{ "@U", "\\Upsilon", "mA" },
	{ "@o", "\\omega", "mA" },
	{ "@O", "\\Omega", "mA" },
	{ "ome", "\\omega", "mA" },
	{ "Ome", "\\Omega", "mA" },

	-- Text environment
	{ "text", "\\text{$0}$1", "mA" },
	{ '"', "\\text{$0}$1", "mA" },

	-- Basic operations
	{ "sr", "^{2}", "mA" },
	{ "cb", "^{3}", "mA" },
	{ "rd", "^{$0}$1", "mA" },
	{ "_", "_{$0}$1", "mA" },
	{ "sts", "_\\text{$0}", "mA" },
	{ "sq", "\\sqrt{ $0 }$1", "mA" },
	{ "//", "\\frac{$0}{$1}$2", "mA" },
	-- Latex Suite's auto-fraction setting, not a data.json snippet.
	{ "/", "\\frac{[[0]]}{$0}$1", "mA", autofraction = true },
	{ "ee", "e^{ $0 }$1", "mA" },
	{ "invs", "^{-1}", "mA" },

	{ [[([^\\])(exp|log|ln)]], "[[0]]\\[[1]]", "rmA" },
	{ "conj", "^{*}", "mA" },
	{ "Re", "\\mathrm{Re}", "mA" },
	{ "Im", "\\mathrm{Im}", "mA" },
	{ "bf", "\\mathbf{$0}", "mA" },
	{ "rm", "\\mathrm{$0}$1", "mA" },

	-- Linear algebra
	{ [[([^\\])(det)]], "[[0]]\\[[1]]", "rmA" },
	{ "trace", "\\mathrm{Tr}", "mA" },

	-- More operations
	{ "([a-zA-Z])hat", "\\hat{[[0]]}", "rmA" },
	{ "([a-zA-Z])bar", "\\bar{[[0]]}", "rmA" },
	{ "([a-zA-Z])dot", "\\dot{[[0]]}", "rmA", priority = -1 },
	{ "([a-zA-Z])ddot", "\\ddot{[[0]]}", "rmA", priority = 1 },
	{ "([a-zA-Z])tilde", "\\tilde{[[0]]}", "rmA" },
	{ "([a-zA-Z])und", "\\underline{[[0]]}", "rmA" },
	{ "([a-zA-Z])vec", "\\vec{[[0]]}", "rmA" },
	{ "([a-zA-Z]),\\.", "\\mathbf{[[0]]}", "rmA" },
	{ "([a-zA-Z])\\.,", "\\mathbf{[[0]]}", "rmA" },
	{ "\\\\(${GREEK}),\\.", "\\boldsymbol{\\[[0]]}", "rmA" },
	{ "\\\\(${GREEK})\\.,", "\\boldsymbol{\\[[0]]}", "rmA" },

	{ "hat", "\\hat{$0}$1", "mA" },
	{ "bar", "\\bar{$0}$1", "mA" },
	{ "dot", "\\dot{$0}$1", "mA", priority = -1 },
	{ "ddot", "\\ddot{$0}$1", "mA" },
	{ "cdot", "\\cdot", "mA" },
	{ "tilde", "\\tilde{$0}$1", "mA" },
	{ "und", "\\underline{$0}$1", "mA" },
	{ "vec", "\\vec{$0}$1", "mA" },
	{ "pmod", "\\pmod{${0:n}}$1", "mA" },

	-- Auto letter subscript: x3 -> x_{3}, x_{3}4 -> x_{34}, \dot{x}3 -> \dot{x}_{3}
	{ "(\\\\${GREEK}|[A-Za-z])(\\d)", "[[0]]_{[[1]]}", "rmA", priority = -1 },
	{ "(\\\\${GREEK}|[A-Za-z])_{(\\d+)}(\\d)", "[[0]]_{[[1]][[2]]}", "rmA", priority = -1 },
	{ "\\\\(${ACCENT})\\{(\\\\${GREEK}|[A-Za-z])\\}(\\d)", "\\[[0]]{[[1]]}_{[[2]]}", "rmA", priority = -1 },
	{
		"\\\\(${ACCENT})\\{(\\\\${GREEK}|[A-Za-z])\\}_\\{(\\d+)\\}(\\d)",
		"\\[[0]]{[[1]]}_{[[2]][[3]]}",
		"rmA",
		priority = -1,
	},
	{
		"\\\\(${ACCENT})\\{\\\\(${ACCENT})\\{(\\\\${GREEK}|[A-Za-z])\\}\\}(\\d)",
		"\\[[0]]{\\[[1]]{[[2]]}}_{[[3]]}",
		"rmA",
		priority = -1,
	},
	{
		"\\\\(${ACCENT})\\{\\\\(${ACCENT})\\{(\\\\${GREEK}|[A-Za-z])\\}\\}_\\{(\\d+)\\}(\\d)",
		"\\[[0]]{\\[[1]]{[[2]]}}_{[[3]][[4]]}",
		"rmA",
		priority = -1,
	},

	{ "xnn", "x_{n}", "mA" },
	{ "\\xii", "x_{i}", "mA", priority = 1 },
	{ "xjj", "x_{j}", "mA" },
	{ "xp1", "x_{n+1}", "mA" },
	{ "ynn", "y_{n}", "mA" },
	{ "yii", "y_{i}", "mA" },
	{ "yjj", "y_{j}", "mA" },

	-- Symbols
	{ "ooo", "\\infty", "mA" },
	{ "sum", "\\sum", "mA" },
	{ "prod", "\\prod", "mA" },
	{ "\\sum", "\\sum_{${0:i}=${1:1}}^{${2:N}} $3", "m" },
	{ "\\prod", "\\prod_{${0:i}=${1:1}}^{${2:N}} $3", "m" },
	{ "lim", "\\lim_{ ${0:n} \\to ${1:\\infty} } $2", "mA" },
	{ "+-", "\\pm", "mA" },
	{ "-+", "\\mp", "mA" },
	{ "...", "\\dots", "mA" },
	{ "nabl", "\\nabla", "mA" },
	{ "xx", "\\times", "mA" },
	{ "**", "\\cdot", "mA" },
	{ "para", "\\parallel", "mA" },

	{ "===", "\\equiv", "mA" },
	{ "!=", "\\neq", "mA" },
	{ ">=", "\\geq", "mA" },
	{ "<=", "\\leq", "mA" },
	{ ">>", "\\gg", "mA" },
	{ "<<", "\\ll", "mA" },
	{ "simm", "\\sim", "mA" },
	{ "sim=", "\\simeq", "mA" },
	{ "prop", "\\propto", "mA" },

	{ "<->", "\\leftrightarrow ", "mA" },
	{ "->", "\\to", "mA" },
	{ "!>", "\\mapsto", "mA" },
	{ "=>", "\\implies", "mA" },
	{ "=<", "\\impliedby", "mA" },

	{ "and", "\\cap", "mA" },
	{ "orr", "\\cup", "mA" },
	{ "inn", "\\in", "mA" },
	{ "notin", "\\not\\in", "mA" },
	{ "\\\\\\", "\\setminus", "mA" },
	{ "sub=", "\\subseteq", "mA" },
	{ "sup=", "\\supseteq", "mA" },
	{ "eset", "\\emptyset", "mA" },
	{ "set", "\\{ $0 \\}$1", "mA" },
	{ "e\\xi sts", "\\exists", "mA", priority = 1 },

	{ "LL", "\\mathcal{L}", "mA" },
	{ "HH", "\\mathcal{H}", "mA" },
	{ "CC", "\\mathbb{C}", "mA" },
	{ "RR", "\\mathbb{R}", "mA" },
	{ "ZZ", "\\mathbb{Z}", "mA" },
	{ "NN", "\\mathbb{N}", "mA" },

	-- Backslash before Greek letters and symbols, and a space after them
	{ "([^\\\\])(${GREEK})", "[[0]]\\[[1]]", "rmA" },
	{ "([^\\\\])(${SYMBOL})", "[[0]]\\[[1]]", "rmA" },

	{ "\\\\(${GREEK}|${SYMBOL}|${MORE_SYMBOLS})([A-Za-z])", "\\[[0]] [[1]]", "rmA" },
	{ "\\\\(${GREEK}|${SYMBOL}) sr", "\\[[0]]^{2}", "rmA" },
	{ "\\\\(${GREEK}|${SYMBOL}) cb", "\\[[0]]^{3}", "rmA" },
	{ "\\\\(${GREEK}|${SYMBOL}) rd", "\\[[0]]^{$0}$1", "rmA" },
	{ "\\\\(${GREEK}) hat", "\\hat{\\[[0]]}", "rmA" },
	{ "\\\\(${GREEK}) dot", "\\dot{\\[[0]]}", "rmA" },
	{ "\\\\(${GREEK}) bar", "\\bar{\\[[0]]}", "rmA" },
	{ "\\\\(${GREEK}) vec", "\\vec{\\[[0]]}", "rmA" },
	{ "\\\\(${GREEK}) tilde", "\\tilde{\\[[0]]}", "rmA" },
	{ "\\\\(${GREEK}) und", "\\underline{\\[[0]]}", "rmA" },

	-- Derivatives and integrals
	{ "par", "\\frac{ \\partial ${0:y} }{ \\partial ${1:x} } $2", "m" },
	{ [[pa([A-Za-z])([A-Za-z])]], "\\frac{ \\partial [[0]] }{ \\partial [[1]] } ", "rm" },
	{ "ddt", "\\frac{d}{dt} ", "mA" },

	{ [[([^\\])int]], "[[0]]\\int", "rmA", priority = -1 },
	{ "\\int", "\\int $0 \\, d${1:x} $2", "m" },
	{ "dint", "\\int_{${0:0}}^{${1:1}} $2 \\, d${3:x} $4", "mA" },
	{ "oint", "\\oint", "mA" },
	{ "iint", "\\iint", "mA" },
	{ "iiint", "\\iiint", "mA" },
	{ "oinf", "\\int_{0}^{\\infty} $0 \\, d${1:x} $2", "mA" },
	{ "infi", "\\int_{-\\infty}^{\\infty} $0 \\, d${1:x} $2", "mA" },

	-- Trigonometry (the space rule skips "h" so sinh, cosh, ... still work)
	{ [[([^\\])(arcsin|sin|arccos|cos|arctan|tan|csc|sec|cot)]], "[[0]]\\[[1]]", "rmA" },
	{ [[\\(arcsin|sin|arccos|cos|arctan|tan|csc|sec|cot)([A-Za-gi-z])]], "\\[[0]] [[1]]", "rmA" },
	{ [[\\(sinh|cosh|tanh|coth)([A-Za-z])]], "\\[[0]] [[1]]", "rmA" },
	{ [[(arccsc|arcsec|arccot)]], "\\operatorname{[[0]]}$0", "rmA", priority = 1 },

	-- Visual operations
	{ "U", "\\underbrace{ ${VISUAL} }_{ $0 }", "mA" },
	{ "O", "\\overbrace{ ${VISUAL} }^{ $0 }", "mA" },
	{ "B", "\\underset{ $0 }{ ${VISUAL} }", "mA" },
	{ "C", "\\cancel{ ${VISUAL} }", "mA" },
	{ "K", "\\cancelto{ $0 }{ ${VISUAL} }", "mA" },
	{ "S", "\\sqrt{ ${VISUAL} }", "mA" },

	-- Physics
	{ "kbt", "k_{B}T", "mA" },
	{ "msun", "M_{\\odot}", "mA" },

	-- Quantum mechanics
	{ "dag", "^{\\dagger}", "mA" },
	{ "o+", "\\oplus ", "mA" },
	{ "ox", "\\otimes ", "mA" },
	{ "bra", "\\bra{$0} $1", "mA" },
	{ "ket", "\\ket{$0} $1", "mA" },
	{ "brk", "\\braket{ $0 | $1 } $2", "mA" },
	{ "outer", "\\ket{${0:\\psi}} \\bra{${0:\\psi}} $1", "mA" },

	-- Chemistry
	{ "pu", "\\pu{ $0 }", "mA" },
	{ "cee", "\\ce{ $0 }", "mA" },
	{ "he4", "{}^{4}_{2}He ", "mA" },
	{ "he3", "{}^{3}_{2}He ", "mA" },
	{ "iso", "{}^{${0:4}}_{${1:2}}${2:He}", "mA" },

	-- Environments
	{ [[([pbBvV]mat)]], "\\begin{[[0]]rix}\n$0\n\\end{[[0]]rix}", "rMA" },
	{ [[(matrix|cases|align|array)]], "\\begin{[[0]]}\n$0\n\\end{[[0]]}", "rMA" },
	{ [[([pbBvV]mat)]], "\\begin{[[0]]rix}$0\\end{[[0]]rix}", "rnA" },
	{ [[(matrix|cases|align|array)]], "\\begin{[[0]]}$0\\end{[[0]]}", "rnA" },

	-- Brackets
	{ "avg", "\\langle $0 \\rangle $1", "mA" },
	{ "norm", "\\lvert $0 \\rvert $1", "mA", priority = 1 },
	{ "Norm", "\\lVert $0 \\rVert $1", "mA", priority = 1 },
	{ "ceil", "\\lceil $0 \\rceil $1", "mA" },
	{ "floor", "\\lfloor $0 \\rfloor $1", "mA" },
	{ "mod", "|$0|$1", "mA" },
	{ "(", "(${VISUAL})", "mA" },
	{ "[", "[${VISUAL}]", "mA" },
	{ "{", "{${VISUAL}}", "mA" },
	{ "(", "($0)$1", "mA" },
	{ "{", "{$0}$1", "mA" },
	{ "[", "[$0]$1", "mA" },
	{ "lr(", "\\left( $0 \\right) $1", "mA" },
	{ "lr{", "\\left\\{ $0 \\right\\} $1", "mA" },
	{ "lr[", "\\left[ $0 \\right] $1", "mA" },
	{ "lr|", "\\left| $0 \\right| $1", "mA" },
	{ "lra", "\\left< $0 \\right> $1", "mA" },

	-- Misc
	{
		"tayl",
		"${0:f}(${1:x} + ${2:h}) = ${0:f}(${1:x}) + ${0:f}'(${1:x})${2:h} + ${0:f}''(${1:x}) \\frac{${2:h}^{2}}{2!} + \\dots$3",
		"mA",
	},
	{
		[[iden(\d)]],
		function(captures)
			local n, rows = tonumber(captures[1]), {}
			for r = 1, n do
				local row = {}
				for c = 1, n do
					row[c] = r == c and "1" or "0"
				end
				rows[r] = table.concat(row, " & ")
			end
			return "\\begin{pmatrix}\n" .. table.concat(rows, " \\\\\n") .. "\n\\end{pmatrix}"
		end,
		"rmA",
	},
	{
		[[(?<=(?:\n|^)[ \t]*>*)(?<marker>\d+[.)]|[-*+])(?<whitespace>[ \t]+)(?<text>.*)dm]],
		function(captures)
			local marker, whitespace, text = captures[1], captures[2], captures[3]
			local indent = string.rep(" ", #marker) .. whitespace
			return marker .. whitespace .. text .. "\n" .. indent .. "$$\n" .. indent .. "\t$0\n" .. indent .. "$$"
		end,
		"rtA",
		priority = 2,
	},
}

local latex_suite = require("latex_suite")
local context = latex_suite.context

local function in_mode(options, ctx)
	return (options:find("t") and ctx == "text")
		or (options:find("m") and (ctx == "inline" or ctx == "display"))
		or (options:find("M") and ctx == "display")
		or (options:find("n") and ctx == "inline")
end

-- Latex Suite's removeSnippetWhitespace: no trailing spaces in inline math.
local function trim_end(body)
	local stops = ""
	while true do
		local rest, stop = body:match("^(.-)(%$%d+)$")
		if not rest then
			break
		end
		body, stops = rest, stop .. stops
	end
	return body:gsub("%s+$", "") .. stops
end

-- Latex Suite numbers tabstops from $0, LuaSnip from 1 ($0 is the exit).
local function nodes(body, snip)
	local out, seen, pos, text = {}, {}, 1, ""
	local function push(node)
		if text ~= "" then
			out[#out + 1] = t(vim.split(text, "\n", { plain = true }))
			text = ""
		end
		out[#out + 1] = node
	end
	while pos <= #body do
		local n, default, stop_end = body:match("^%${(%d+):([^}]*)}()", pos)
		if not n then
			n, stop_end = body:match("^%$(%d+)()", pos)
		end
		local capture, capture_end = body:match("^%[%[(%d+)%]%]()", pos)
		if n then
			n = tonumber(n) + 1
			push(seen[n] and rep(n) or i(n, default))
			seen[n] = true
			pos = stop_end
		elseif capture then
			text = text .. (snip.captures[tonumber(capture) + 1] or "")
			pos = capture_end
		elseif body:sub(pos, pos + 8) == "${VISUAL}" then
			push(t(snip.env.LS_SELECT_RAW))
			pos = pos + 9
		else
			text = text .. body:sub(pos, pos)
			pos = pos + 1
		end
	end
	push(nil)
	return out
end

local function resolver(options, visual)
	return function(_, line_to_cursor, trigger)
		local ctx = context()
		if not in_mode(options, ctx) then
			return nil
		end
		if visual and vim.b.LUASNIP_SELECT_RAW == nil then
			return nil
		end
		if options:find("w") then
			local before = line_to_cursor:sub(-#trigger - 1, -#trigger - 1)
			if before ~= "" and not delimiters:find(before, 1, true) then
				return nil
			end
		end

		return { env_override = { LATEX_SUITE_CONTEXT = ctx } }
	end
end

-- Latex Suite's auto-fraction: "/" makes the term before it the numerator.
-- The term ends at an unbracketed autofractionBreakingChars ("+-=\t"), space,
-- newline, "$" or opening bracket; a space after a Greek letter does not end it.
local fraction_greek = vim.split(
	"alpha|beta|gamma|Gamma|delta|Delta|epsilon|varepsilon|zeta|eta|theta|Theta|iota|kappa|lambda|Lambda|mu|nu|omicron|xi|Xi|pi|Pi|rho|sigma|Sigma|tau|upsilon|Upsilon|varphi|phi|Phi|chi|psi|Psi|omega|Omega",
	"|",
	{ plain = true }
)
local openers = { [")"] = "(", ["]"] = "[", ["}"] = "{" }
local breaking = " $([{\n+-=\t"

-- 1-based start of the numerator in `text` (the equation up to the cursor).
local function numerator_start(text)
	for _, name in ipairs(fraction_greek) do
		text = text:gsub(name .. " ([^ ])", name .. "#%1")
	end
	local k = #text
	while k >= 1 do
		local c = text:sub(k, k)
		if openers[c] then
			local depth = 0
			repeat
				local b = text:sub(k, k)
				depth = depth + (b == c and 1 or b == openers[c] and -1 or 0)
				k = k - 1
			until depth == 0 or k < 1
			if depth ~= 0 then
				return nil
			end
		elseif breaking:find(c, 1, true) then
			return k + 1
		else
			k = k - 1
		end
	end
	return 1
end

-- Latex Suite's isWithinEnvironment for autofractionExcludedEnvs ^{...} and \pu{...}:
-- the cursor (0-based `pos` in `text`) is inside `open` and its matching "}".
local function within(text, pos, open)
	local starts, from = {}, 1
	while true do
		local at = text:find(open, from, true)
		if not at or at > pos then
			break
		end
		starts[#starts + 1], from = at, at + 1
	end
	for k = #starts, 1, -1 do
		local left, depth, right = starts[k], 0, nil
		for j = left + #open - 1, #text do
			local c = text:sub(j, j)
			depth = depth + (c == "{" and 1 or c == "}" and -1 or 0)
			if depth == 0 then
				right = j
				break
			end
		end
		if not right then
			return false
		elseif right - 1 >= pos and pos >= left - 1 + #open then
			return true
		elseif left <= 1 then
			return false
		end
	end
	return false
end

local function autofraction()
	local ctx, eq = context()
	if not in_mode("m", ctx) then
		return nil
	end
	-- The "/" is already typed; Latex Suite runs before it is.
	local pos = eq.offset - 1
	local text = eq.text:sub(1, pos) .. eq.text:sub(eq.offset + 1)
	if within(text, pos, "^{") or within(text, pos, "\\pu{") then
		return nil
	end
	local start = numerator_start(text:sub(1, pos))
	if not start or start > pos then
		return nil
	end
	-- (a+b)/ -> \frac{a+b}{}, but (a)(b)/ keeps its brackets.
	local numerator = text:sub(start, pos)
	if numerator:match("^%(.*%)$") then
		local depth = 0
		for k = 1, #numerator do
			local c = numerator:sub(k, k)
			depth = depth + (c == "(" and 1 or c == ")" and -1 or 0)
			if depth == 0 then
				if k == #numerator then
					numerator = numerator:sub(2, -2)
				end
				break
			end
		end
	end
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local sr, sc = latex_suite.position(eq, start - 1)
	return {
		captures = { numerator },
		clear_region = { from = { sr, sc }, to = { row - 1, col } },
		env_override = { LATEX_SUITE_CONTEXT = ctx },
	}
end

-- Latex Suite's auto-enlarge brackets, for snippets that insert a trigger.
local enlarge = {
	[-1] = {
		[require("luasnip.util.events").pre_expand] = function(_, args)
			local row, col = latex_suite.enlarge(args.expand_pos[1], args.expand_pos[2])
			if row then
				-- Same mark LuaSnip made, which the edits would leave before \left(.
				local ns = require("luasnip.session").ns_id
				vim.api.nvim_buf_set_extmark(0, ns, row, col, { id = args.expand_pos_mark_id, right_gravity = false })
			end
		end,
	},
}

for index, def in ipairs(defs) do
	def.trig = def[3]:find("r") and def[1]:gsub("%${[%u_]+}", variables) or def[1]
	def.index = index
end

-- Latex Suite tries higher priority first, then the longer trigger, then file order.
table.sort(defs, function(a, b)
	local pa, pb = a.priority or 0, b.priority or 0
	if pa ~= pb then
		return pa > pb
	elseif #a.trig ~= #b.trig then
		return #a.trig > #b.trig
	end
	return a.index < b.index
end)

local snippets = {}
for rank, def in ipairs(defs) do
	local replacement, options = def[2], def[3]
	local visual = type(replacement) == "string" and replacement:find("${VISUAL}", 1, true) ~= nil
	local enlarges = false
	for _, trigger in ipairs(latex_suite.enlarge_triggers) do
		enlarges = enlarges or type(replacement) == "string" and replacement:find(trigger, 1, true) ~= nil
	end
	snippets[rank] = s({
		trig = def.trig,
		trigEngine = options:find("r") and "ecma" or "plain",
		wordTrig = false,
		snippetType = options:find("A") and "autosnippet" or "snippet",
		priority = 2000 - rank,
		hidden = true,
		resolveExpandParams = def.autofraction and autofraction or resolver(options, visual),
	}, {
		d(1, function(_, parent)
			local snip = parent.snippet
			local body = type(replacement) == "function" and replacement(snip.captures) or replacement
			if snip.env.LATEX_SUITE_CONTEXT == "inline" then
				body = trim_end(body)
			end
			return sn(nil, nodes(body, snip))
		end),
	}, { callbacks = enlarges and enlarge or nil })
end

return snippets
