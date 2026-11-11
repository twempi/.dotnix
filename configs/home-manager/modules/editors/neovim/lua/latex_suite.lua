-- Editor features of Obsidian's Latex Suite, set up like
-- ~/Documents/notes/.obsidian/plugins/obsidian-latex-suite/data.json (plugin 1.13.4).
-- The snippets and auto-fraction live in lua/snippets/markdown.lua; Tab, Enter and
-- Backspace are wired in lua/plugins/cmp.lua.
local M = {}

-- data.json settings, plus plugin defaults for keys it predates.
local matrix_envs = {
	pmatrix = true,
	cases = true,
	align = true,
	gather = true,
	bmatrix = true,
	Bmatrix = true,
	vmatrix = true,
	Vmatrix = true,
	array = true,
	matrix = true,
}
local matrix_macros = { eqalign = true }
local tabout_closing = {}
-- stylua: ignore
for _, s in ipairs({ ")", "]", "\\rbrack", "\\}", "\\rbrace", "\\rangle", "\\rvert", "\\rVert", "\\rfloor", "\\rceil", "\\urcorner", "}" }) do
	tabout_closing[s] = true
end
M.enlarge_triggers = { "\\sum", "\\int", "\\frac", "\\prod", "\\bigcup", "\\bigcap" }
local force_math_languages = { math = true }
-- data.json's "▶"; pdflatex has no glyph for the character itself.
local preview_cursor = "{\\blacktriangleright}"

local function set(list)
	local out = {}
	for _, v in ipairs(list) do
		out[v] = true
	end
	return out
end

local lefts = set({ "\\left", "\\bigl", "\\Bigl", "\\biggl", "\\Biggl" })
local rights = set({ "\\right", "\\bigr", "\\Bigr", "\\biggr", "\\Biggr" })
-- stylua: ignore
local sizes = set({
	"\\big", "\\Big", "\\bigg", "\\Bigg", "\\bigl", "\\Bigl", "\\biggl", "\\Biggl",
	"\\bigr", "\\Bigr", "\\biggr", "\\Biggr", "\\left", "\\right",
})
-- Tokens that can follow \left or \right.
-- stylua: ignore
local delimiters = set({
	"(", ")", "[", "]", "\\lbrack", "\\rbrack", "\\{", "\\}", "\\lbrace", "\\rbrace", "<", ">", "\\langle",
	"\\rangle", "\\lt", "\\gt", "|", "\\vert", "\\lvert", "\\rvert", "\\|", "\\Vert", "\\lVert", "\\rVert",
	"\\lfloor", "\\rfloor", "\\lceil", "\\rceil", "\\ulcorner", "\\urcorner", "/", "\\\\", "\\backslash",
	"\\uparrow", "\\downarrow", "\\Uparrow", "\\Downarrow", ".",
})
local pairs_of = {
	["("] = ")",
	["["] = "]",
	["{"] = "}",
	["\\lbrack"] = "\\rbrack",
	["\\lbrace"] = "\\rbrace",
	["\\langle"] = "\\rangle",
	["\\lvert"] = "\\rvert",
	["\\lVert"] = "\\rVert",
	["\\lfloor"] = "\\rfloor",
	["\\lceil"] = "\\rceil",
	["\\ulcorner"] = "\\urcorner",
}
local closers = {}
for _, close in pairs(pairs_of) do
	closers[close] = true
end
-- Auto-enlarge skips { } groups but takes \{ \}.
local enlarge_pairs = vim.tbl_extend("force", pairs_of, { ["{"] = false, ["\\{"] = "\\}" })
local enlarge_closers = vim.tbl_extend("force", closers, { ["}"] = false, ["\\}"] = true })

-- Latex Suite's tokenizer: \command, \ plus one character, a % comment, or one
-- character. Offsets are 0-based, `stop` exclusive.
function M.tokens(text)
	local list, k = {}, 1
	while k <= #text do
		local c = text:sub(k, k)
		local stop
		if c:match("%s") then
			k = k + 1
		else
			if c == "%" then
				stop = text:find("\n", k, true) or #text + 1
			elseif c == "\\" then
				stop = text:match("^\\%a+()", k) or math.min(k + 2, #text + 1)
			else
				stop = k + 1
			end
			list[#list + 1] = { start = k - 1, stop = stop - 1, text = text:sub(k, stop - 1) }
			k = stop
		end
	end
	return list
end

local function get_text(sr, sc, er, ec)
	return table.concat(vim.api.nvim_buf_get_text(0, sr, sc, er, ec, {}), "\n")
end

-- 0-based offset into `text`, which starts at row, col -> buffer row, col.
local function locate(row, col, text, offset)
	local lines = vim.split(text:sub(1, offset), "\n", { plain = true })
	if #lines == 1 then
		return row, col + #lines[1]
	end
	return row + #lines - 1, #lines[#lines]
end

function M.position(eq, offset)
	return locate(eq.inner[1], eq.inner[2], eq.text, offset)
end

local function before(r1, c1, r2, c2)
	return r1 < r2 or (r1 == r2 and c1 < c2)
end

-- The ```math (forceMathLanguages) content of a fenced block, if it is one.
local function forced_math(block, buf)
	local language, content
	for child in block:iter_children() do
		if child:type() == "info_string" then
			language = vim.treesitter.get_node_text(child, buf or 0):match("^%S+")
		elseif child:type() == "code_fence_content" then
			content = child
		end
	end
	return force_math_languages[language] and content or nil
end

-- The math around row, col (0-based; default the cursor) as
-- { display, text, offset, inner = { sr, sc, er, ec }, outer = { ... } },
-- or nil and "code" or "text".
function M.equation(row, col)
	if not row then
		row, col = unpack(vim.api.nvim_win_get_cursor(0))
		row = row - 1
	end
	if vim.treesitter.language.get_lang(vim.bo.filetype) ~= "markdown" then
		return nil, "text"
	end
	local ok, parser = pcall(vim.treesitter.get_parser, 0, "markdown")
	if not ok or not parser then
		return nil, "text"
	end
	parser:parse({ row, row + 1 })
	local pos = { row, col, row, col }
	local eq

	local node = parser:named_node_for_range(pos)
	while node do
		local type = node:type()
		if type == "fenced_code_block" then
			local content = forced_math(node)
			if not content then
				return nil, "code"
			end
			local sr, sc, er, ec = content:range()
			local osr, osc, oer, oec = node:range()
			if oec == 0 and oer > osr then
				oer = oer - 1
				oec = #vim.api.nvim_buf_get_lines(0, oer, oer + 1, false)[1]
			end
			eq = { display = true, inner = { sr, sc, er, ec }, outer = { osr, osc, oer, oec } }
			break
		elseif type == "indented_code_block" or type == "minus_metadata" then
			return nil, "code"
		end
		node = node:parent()
	end

	if not eq then
		local inline = parser:children().markdown_inline
		node = inline and inline:named_node_for_range(pos)
		while node do
			if node:type() == "code_span" then
				return nil, "code"
			elseif node:type() == "latex_block" then
				local sr, sc, er, ec = node:range()
				-- Right after the closing $ is text again.
				if not (before(sr, sc, row, col) and before(row, col, er, ec)) then
					return nil, "text"
				end
				local delim = #vim.treesitter.get_node_text(node, 0):match("^%$*")
				eq = { display = delim == 2, inner = { sr, sc + delim, er, ec - delim }, outer = { sr, sc, er, ec } }
				break
			end
			node = node:parent()
		end
	end
	if not eq then
		return nil, "text"
	end

	local sr, sc, er, ec = unpack(eq.inner)
	eq.text = get_text(sr, sc, er, ec)
	if before(row, col, sr, sc) then
		eq.offset = 0
	elseif before(er, ec, row, col) then
		eq.offset = #eq.text
	else
		eq.offset = #get_text(sr, sc, row, col)
	end
	return eq
end

-- "text", "code", "inline" or "display", and the equation.
function M.context()
	local eq, ctx = M.equation()
	if eq then
		return eq.display and "display" or "inline", eq
	end
	return ctx
end

-- Whether the cursor is in `$` or `$$` math once the cursor line reads `line`. For
-- autopairs, which decides before the key lands: a blank line in `$$ $$` splits
-- the paragraph, so it is only math after the key is typed.
function M.math_with_line(line)
	if vim.treesitter.language.get_lang(vim.bo.filetype) ~= "markdown" then
		return false
	end
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	lines[row] = line
	local parser = vim.treesitter.get_string_parser(table.concat(lines, "\n"), "markdown")
	parser:parse(true)
	local inline = parser:children().markdown_inline
	local node = inline and inline:named_node_for_range({ row - 1, col, row - 1, col })
	while node do
		if node:type() == "latex_block" then
			local sr, sc, er, ec = node:range()
			return before(sr, sc, row - 1, col) and before(row - 1, col, er, ec)
		end
		node = node:parent()
	end
	return false
end

-- At the cursor position from when the key was pressed (row 1-based).
local function insert(text, row, col)
	local lines = vim.split(text, "\n", { plain = true })
	vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)
	if #lines == 1 then
		vim.api.nvim_win_set_cursor(0, { row, col + #text })
	else
		vim.api.nvim_win_set_cursor(0, { row + #lines - 1, #lines[#lines] })
	end
end

-- Runs `action` after blink's expr mapping, where the buffer is locked.
local function handled(action)
	if not action then
		return false
	end
	vim.schedule(action)
	return true
end

-- Innermost \begin{env} or \command{ argument around the cursor.
local function enclosing(eq)
	local text, stack, last, k = eq.text:sub(1, eq.offset), {}, nil, 1
	while k <= #text do
		local kind, name, stop = text:match("^\\(%a+)(%b{})()", k)
		if kind == "begin" then
			stack[#stack + 1] = { env = name:sub(2, -2) }
			last, k = nil, stop
		elseif kind == "end" then
			for i = #stack, 1, -1 do
				if stack[i].env == name:sub(2, -2) then
					for j = #stack, i, -1 do
						stack[j] = nil
					end
					break
				end
			end
			last, k = nil, stop
		else
			local word, word_stop = text:match("^\\(%a+)()", k)
			local c = text:sub(k, k)
			if word then
				last, k = word, word_stop
			elseif c == "\\" then
				last, k = nil, k + 2
			elseif c == "{" then
				stack[#stack + 1] = { command = last or "" }
				last, k = nil, k + 1
			elseif c == "}" then
				local top = stack[#stack]
				if top and top.command then
					stack[#stack] = nil
					last = top.command
				else
					last = nil
				end
				k = k + 1
			else
				if c:match("%S") then
					last = nil
				end
				k = k + 1
			end
		end
	end
	return stack[#stack]
end

local function in_matrix(eq)
	local top = eq and enclosing(eq)
	return top ~= nil and (matrix_envs[top.env] or matrix_macros[top.command]) == true
end

-- First unmatched closing bracket after the cursor on this line (tabout in a matrix).
local function line_tabout()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local depth = 0
	for _, tok in ipairs(M.tokens(vim.api.nvim_get_current_line():sub(col + 1))) do
		if closers[tok.text] and tabout_closing[tok.text] then
			if depth == 0 then
				return col + tok.stop
			end
			depth = depth - 1
		elseif pairs_of[tok.text] and tabout_closing[pairs_of[tok.text]] then
			depth = depth + 1
		end
	end
end

-- Leading `& ` of the current row, repeated on the new one.
local function matrix_indent()
	local line, best, indent = vim.api.nvim_get_current_line(), math.huge, ""
	for _, pattern in ipairs({ "^()([%s&]+)", "()\\begin{[^%]]*}([%s&]+)", "()\\\\([%s&]+)" }) do
		local at, run = line:match(pattern)
		if at and at < best then
			best, indent = at, run
		end
	end
	return (indent:gsub("^%s+", ""))
end

-- Tabout: past the next closing bracket, or out of the equation at its end.
local function tabout(eq)
	local list = M.tokens(eq.text)
	local first = #list + 1
	for k, tok in ipairs(list) do
		if tok.stop > eq.offset then
			first = k
			break
		end
	end
	for k = first, #list do
		local tok, prev, next = list[k], list[k - 1], list[k + 1]
		local closing
		if prev and rights[prev.text] and delimiters[tok.text] then
			closing = true
		elseif prev and lefts[prev.text] and delimiters[tok.text] then
			closing = false
		else
			closing = tabout_closing[tok.text] == true
		end
		if closing or (rights[tok.text] and not (next and delimiters[next.text])) then
			return function()
				local row, col = M.position(eq, tok.stop)
				vim.api.nvim_win_set_cursor(0, { row + 1, col })
			end
		end
	end

	-- taboutExitEquationOnlyOnEOL
	if eq.text:sub(eq.offset + 1):match("%S") then
		return nil
	end
	return function()
		if not eq.display then
			vim.api.nvim_win_set_cursor(0, { eq.outer[3] + 1, eq.outer[4] })
			return
		end
		local row = vim.api.nvim_win_get_cursor(0)[1]
		local line = vim.api.nvim_get_current_line()
		if line:match("%s+$") then
			vim.api.nvim_buf_set_lines(0, row - 1, row, false, { (line:gsub("%s+$", "")) })
		end
		local indent = vim.api.nvim_buf_get_lines(0, eq.outer[1], eq.outer[1] + 1, false)[1]:match("^%s*")
		local last = eq.outer[3]
		if last == vim.api.nvim_buf_line_count(0) - 1 then
			vim.api.nvim_buf_set_lines(0, last + 1, last + 1, false, { indent })
			vim.api.nvim_win_set_cursor(0, { last + 2, #indent })
		elseif vim.api.nvim_buf_get_lines(0, last + 1, last + 2, false)[1]:match("^%s*$") then
			vim.api.nvim_buf_set_lines(0, last + 1, last + 2, false, { indent })
			vim.api.nvim_win_set_cursor(0, { last + 2, #indent })
		else
			vim.api.nvim_win_set_cursor(0, { last + 2, 0 })
		end
	end
end

function M.tab()
	local eq = M.equation()
	if not eq then
		return false
	end
	if in_matrix(eq) then
		local stop = line_tabout()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		return handled(function()
			if stop then
				vim.api.nvim_win_set_cursor(0, { row, stop })
			else
				insert(" & ", row, col)
			end
		end)
	end
	return handled(tabout(eq))
end

-- Enter in a matrix: a new row.
function M.enter()
	local eq = M.equation()
	if not in_matrix(eq) then
		return false
	end
	local indent = matrix_indent()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	return handled(function()
		insert(eq.display and " \\\\\n" .. indent or " \\\\  " .. indent, row, col)
	end)
end

-- Shift-Enter in a matrix: past its \end{...} (display) or out of the equation.
function M.exit()
	local eq = M.equation()
	if not in_matrix(eq) then
		return false
	end
	if not eq.display then
		return handled(function()
			vim.api.nvim_win_set_cursor(0, { eq.outer[3] + 1, eq.outer[4] })
		end)
	end
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local next = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
	if not next then
		return false
	end
	local env, after_end = next:match("\\end{([^}]*)}()")
	local col = #next
	if env and matrix_envs[env] then
		col = after_end - 1
	end
	return handled(function()
		vim.api.nvim_win_set_cursor(0, { row + 1, col })
	end)
end

-- vimMatrixEnter: `o` on a display-math matrix row starts the next row.
local function matrix_o()
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local line = vim.api.nvim_get_current_line()
	local eq = #line > 0 and M.equation(row, #line - 1)
	if eq and eq.display then
		eq.offset = eq.offset + 1
		if in_matrix(eq) then
			return "A<Cmd>lua require('latex_suite').enter()<CR>"
		end
	end
	return "o"
end

-- Auto-enlarge brackets: \left( \right) around brackets that contain a
-- trigger, or that enclose row, col where a snippet with one is expanding.
-- Returns where row, col moved to.
function M.enlarge(row, col)
	local eq = M.equation(row, col)
	if not eq then
		return
	end
	local list, stack, edits = M.tokens(eq.text), {}, {}
	for k, tok in ipairs(list) do
		if enlarge_pairs[tok.text] then
			stack[#stack + 1] = k
		elseif enlarge_closers[tok.text] then
			for i = #stack, 1, -1 do
				local open_k = stack[i]
				local open = list[open_k]
				if enlarge_pairs[open.text] == tok.text then
					for j = #stack, i, -1 do
						stack[j] = nil
					end
					local sized = (list[open_k - 1] and sizes[list[open_k - 1].text])
						or (list[k - 1] and sizes[list[k - 1].text])
					local inner = eq.text:sub(open.stop + 1, tok.start)
					local wanted = open.stop <= eq.offset and eq.offset <= tok.start
					for _, trigger in ipairs(M.enlarge_triggers) do
						wanted = wanted or inner:find(trigger, 1, true) ~= nil
					end
					if wanted and not sized then
						edits[#edits + 1] = { tok, " \\right" .. tok.text }
						edits[#edits + 1] = { open, "\\left" .. open.text .. " " }
					end
					break
				end
			end
		end
	end
	table.sort(edits, function(a, b)
		return a[1].start > b[1].start
	end)
	local text, offset = eq.text, eq.offset
	for _, edit in ipairs(edits) do
		local tok = edit[1]
		local sr, sc = M.position(eq, tok.start)
		local er, ec = M.position(eq, tok.stop)
		vim.api.nvim_buf_set_text(0, sr, sc, er, ec, { edit[2] })
		text = text:sub(1, tok.start) .. edit[2] .. text:sub(tok.stop + 1)
		if tok.stop <= eq.offset then
			offset = offset + #edit[2] - #tok.text
		end
	end
	return locate(eq.inner[1], eq.inner[2], text, offset)
end

-- Color paired brackets: by depth in math, red when unmatched.
local ns = vim.api.nvim_create_namespace("latex_suite")
local colored = { ["("] = ")", ["["] = "]", ["{"] = "}", ["\\{"] = "\\}" }
local colored_close = set({ ")", "]", "}", "\\}" })

local function color(buf, row, col, text)
	local function mark(tok, group)
		local r, c = locate(row, col, text, tok.start)
		vim.api.nvim_buf_set_extmark(buf, ns, r, c, { end_col = c + #tok.text, hl_group = group, priority = 150 })
	end
	local stack = {}
	for _, tok in ipairs(M.tokens(text)) do
		if colored[tok.text] then
			stack[#stack + 1] = tok
		elseif colored_close[tok.text] then
			local open = table.remove(stack)
			if open and colored[open.text] == tok.text then
				local group = "LatexSuiteBracket" .. (#stack % 3)
				mark(open, group)
				mark(tok, group)
			else
				mark(tok, "LatexSuiteBracketMismatch")
				if open then
					mark(open, "LatexSuiteBracketMismatch")
				end
			end
		end
	end
	for _, open in ipairs(stack) do
		mark(open, "LatexSuiteBracketMismatch")
	end
end

local latex_query, fence_query
local function color_brackets(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
	if not ok or not parser then
		return
	end
	latex_query = latex_query or vim.treesitter.query.parse("markdown_inline", "(latex_block) @math")
	fence_query = fence_query or vim.treesitter.query.parse("markdown", "(fenced_code_block) @block")
	local win = vim.fn.bufwinid(buf)
	if win == -1 then
		return
	end
	local top, bot = vim.fn.line("w0", win) - 1, vim.fn.line("w$", win)
	parser:parse({ top, bot })

	for _, tree in pairs(parser:trees()) do
		for _, block in fence_query:iter_captures(tree:root(), buf, top, bot) do
			local content = forced_math(block, buf)
			if content then
				local row, col = content:range()
				color(buf, row, col, vim.treesitter.get_node_text(content, buf))
			end
		end
	end
	local inline = parser:children().markdown_inline
	for _, tree in pairs(inline and inline:trees() or {}) do
		for _, node in latex_query:iter_captures(tree:root(), buf, top, bot) do
			local row, col = node:range()
			color(buf, row, col, vim.treesitter.get_node_text(node, buf))
		end
	end
end

-- Math preview: the rendered equation in a float above it, with the cursor
-- marked. Needs a terminal with the kitty graphics protocol.
local preview ---@type { src: string, win: snacks.win, placement: snacks.image.Placement }?
local pending ---@type { src: string, win: snacks.win, placement: snacks.image.Placement }?

local function close(p)
	if p then
		p.placement:close()
		p.win:close()
	end
end

local function preview_close()
	close(preview)
	close(pending)
	preview, pending = nil, nil
end

local function preview_update()
	local eq = vim.fn.mode() ~= "c" and M.equation()
	if not (eq and Snacks and Snacks.image.terminal.env().supported) then
		return preview_close()
	end

	local text = eq.text:sub(1, eq.offset) .. preview_cursor .. eq.text:sub(eq.offset + 1)
	if not eq.display then
		text = "\\textstyle " .. text
	end
	local img = { content = text, ext = "math.tex" }
	Snacks.image.doc.transforms.latex(img, { buf = vim.api.nvim_get_current_buf() })
	local root = Snacks.image.config.cache
	vim.fn.mkdir(root, "p")
	local src = root .. "/" .. vim.fn.sha256(img.content):sub(1, 8) .. "-content.math.tex"
	if (pending or preview or {}).src == src then
		return
	end
	if vim.fn.filereadable(src) == 0 then
		local fd = assert(io.open(src, "w"))
		fd:write(img.content)
		fd:close()
	end

	-- Anchor at the start of the equation, or the cursor if that is off screen.
	local anchor = vim.fn.screenpos(0, eq.outer[1] + 1, eq.outer[2] + 1)
	if anchor.row == 0 then
		anchor = { row = vim.fn.screenrow(), col = vim.fn.screencol() }
	end
	local win = Snacks.win(Snacks.win.resolve(Snacks.image.config.doc, "snacks_image", {
		show = false,
		enter = false,
		relative = "editor",
		wo = { winblend = Snacks.image.terminal.env().placeholders and 0 or nil },
	}))
	win:open_buf()
	close(pending)
	local this
	this = {
		src = src,
		win = win,
		placement = Snacks.image.placement.new(
			win.buf,
			src,
			Snacks.config.merge({}, Snacks.image.config.doc, {
				inline = false,
				on_update_pre = function()
					if pending ~= this then
						return
					end
					local loc = this.placement:state().loc
					win.opts.width, win.opts.height = loc.width, loc.height
					-- mathPreviewPositionIsAbove, unless there is no room.
					local row = anchor.row - 1 - (loc.height + 2)
					win.opts.row = row >= 0 and row or anchor.row
					win.opts.col = anchor.col - 1
					win:show()
					close(preview)
					preview, pending = this, nil
				end,
			})
		),
	}
	pending = this
end

function M.setup()
	local function highlights()
		-- Latex Suite's dark-theme bracket colors.
		vim.api.nvim_set_hl(0, "LatexSuiteBracket0", { fg = "#47b8ff", default = true })
		vim.api.nvim_set_hl(0, "LatexSuiteBracket1", { fg = "#ff55cd", default = true })
		vim.api.nvim_set_hl(0, "LatexSuiteBracket2", { fg = "#73ff63", default = true })
		vim.api.nvim_set_hl(0, "LatexSuiteBracketMismatch", { fg = "#ff1212", default = true })
	end
	highlights()

	local group = vim.api.nvim_create_augroup("latex_suite", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "markdown",
		callback = function(args)
			local buf = args.buf
			vim.keymap.set("n", "o", matrix_o, { buffer = buf, expr = true, desc = "Open line (matrix row)" })

			local update = Snacks and Snacks.util.debounce(preview_update, { ms = 150 }) or function() end
			vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI", "WinScrolled" }, {
				group = group,
				buffer = buf,
				callback = function()
					color_brackets(buf)
					update()
				end,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged" }, {
				group = group,
				buffer = buf,
				callback = function()
					update()
				end,
			})
			vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
				group = group,
				buffer = buf,
				callback = preview_close,
			})
			vim.schedule(function()
				color_brackets(buf)
			end)
		end,
	})
end

return M
