local M = {
	buf = -1,
	win = -1,
	max_items = 20,
}

function M.init_buffer()
	if vim.api.nvim_buf_is_valid(M.buf) then
		return
	end
	M.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[M.buf].bufhidden = "wipe"
	vim.bo[M.buf].buftype = "nofile"
	vim.api.nvim_buf_set_name(M.buf, "pumenu")
end

function M.update_window()
	local height = math.min(#M.items, M.max_items, math.max(vim.o.lines - M.row - 1, M.row))
	M.height = height
	local col = M.col
	local row
	if M.row == 0 then
		row = vim.o.lines - vim.o.cmdheight - height
	elseif height > vim.o.lines - M.row - 1 then
		row = M.row - height
	else
		row = M.row + 1
	end
	if M.row ~= 0 and M.col ~= 0 then
		col = col - 1
	end
	local width = M.width
	vim.api.nvim_win_set_config(M.win, { relative = "editor", width = width, height = height, row = row, col = col })
end

function M.init_window()
	if not vim.api.nvim_win_is_valid(M.win) then
		M.win = vim.api.nvim_open_win(M.buf, false, {
			relative = "editor",
			width = 1,
			height = 1,
			row = 1,
			col = 1,
			style = "minimal",
			zindex = 250,
			focusable = false,
		})
		vim.wo[M.win].wrap = false
	end
	vim.api.nvim_win_set_hl_ns(M.win, M.ns)
	M.update_window()
end

function M.render_scrollbar()
	if #M.items <= M.height then
		return
	end
	local first_line = vim.fn.line("w0", M.win)
	local last_line = vim.fn.line("w$", M.win)
	local thumb_size = math.ceil(M.height * M.height / #M.items)
	local thumb_pos = math.floor(first_line / #M.items * M.height)
	thumb_pos = math.min(thumb_pos + first_line, last_line - thumb_size + 1)
	for i = first_line, last_line do
		local is_thumb = i >= thumb_pos and i < thumb_pos + thumb_size
		local hl_group = is_thumb and "PmenuThumb" or "PmenuSbar"
		vim.api.nvim_buf_set_extmark(
			M.buf,
			M.ns,
			i - 1,
			0,
			{ virt_text_pos = "right_align", virt_text = { { " ", hl_group } } }
		)
	end
end

function M.highlight() end

function M.render()
	M.init_buffer()
	M.init_window()
	vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, M.string_items)
	if M.selected ~= -1 then
		vim.api.nvim_buf_set_extmark(
			M.buf,
			M.ns,
			M.selected,
			0,
			{ end_col = M.kind_col_start, strict = false, hl_group = "PmenuSel" }
		)
		local has_kind = M.string_items[M.selected + 1]:sub(M.kind_col_start + 1, M.kind_col_start + 1) ~= " "
		local has_menu = M.string_items[M.selected + 1]:sub(M.menu_col_start + 1, M.menu_col_start + 1) ~= " "

		local hl_kind_sel = has_kind and "PmenuKindSel" or "PmenuSel"
		local hl_menu_sel = has_menu and "PmenuExtraSel" or "PmenuSel"

		vim.api.nvim_buf_set_extmark(
			M.buf,
			M.ns,
			M.selected,
			M.kind_col_start,
			{ end_col = M.kind_col_end, hl_group = hl_kind_sel }
		)
		vim.api.nvim_buf_set_extmark(
			M.buf,
			M.ns,
			M.selected,
			M.menu_col_start,
			{ end_col = M.menu_col_end, hl_group = hl_menu_sel }
		)
		vim.api.nvim_win_set_cursor(M.win, { M.selected + 1, 0 })
	end
	M.render_scrollbar()
end

function M.exit()
	vim.api.nvim_win_close(M.win, true)
	M.win = -1
	M.buf = -1
end

function M.format(items)
	local word_len, kind_len, menu_len = 0, 0, 0
	local string_items = {}
	for _, item in ipairs(items) do
		if M.row == 0 or M.col ~= 0 then
			item[1] = " " .. item[1]
		end
		word_len = math.max(word_len, #item[1])
		kind_len = math.max(kind_len, #item[2])
		menu_len = math.max(menu_len, #item[3])
	end
	local has_kind = kind_len == 0 and 0 or 1
	local has_menu = menu_len == 0 and 0 or 1
	for _, item in ipairs(items) do
		item[1] = item[1]
			.. string.rep(" ", word_len - #item[1])
			.. (" "):rep(has_kind + has_menu - has_kind * has_menu)
			.. (" "):rep(3 * (1 - has_kind) * (1 - has_menu))
		item[2] = item[2]
			.. string.rep(" ", kind_len - #item[2])
			.. (" "):rep(has_menu * has_kind)
			.. (" "):rep(3 * (1 - has_menu) * has_kind)
		item[3] = item[3] .. string.rep(" ", menu_len - #item[3]) .. (" "):rep(3 * has_menu)
		local match = item[1] .. item[2] .. item[3]
		string_items[#string_items + 1] = match
	end
	local kind_col_start, kind_col_end = #items[1][1], #items[1][1] + #items[1][2]
	local menu_col_start, menu_col_end = #items[1][1] + #items[1][2], #items[1][1] + #items[1][2] + #items[1][3]
	M.width = word_len + has_kind + kind_len + has_menu + menu_len + 3
	return string_items, kind_col_start, kind_col_end, menu_col_start, menu_col_end
end

function M.on_show(...)
	M.items, M.selected, M.row, M.col, _ = ...
	M.string_items, M.kind_col_start, M.kind_col_end, M.menu_col_start, M.menu_col_end = M.format(M.items)
	M.render()
end

function M.on_select(...)
	M.selected = ...
	M.render()
end

function M.on_hide()
	M.exit()
end

function M.handler(event, ...)
	if event == "popupmenu_show" then
		M.on_show(...)
	elseif event == "popupmenu_select" then
		M.on_select(...)
	elseif event == "popupmenu_hide" then
		M.on_hide()
	end
end

function M.setup(opts)
	M.max_items = opts.max_items
	M.ns = vim.api.nvim_create_namespace("ed-pumenu")
	vim.api.nvim_set_hl(M.ns, "Normal", { link = "Pmenu" })
end

return M
