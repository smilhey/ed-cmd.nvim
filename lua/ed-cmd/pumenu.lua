local M = {
	buf = -1,
	win = -1,
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

function M.init_window()
	if not vim.api.nvim_win_is_valid(M.win) then
		M.win = vim.api.nvim_open_win(M.buf, false, {
			relative = "editor",
			width = M.width,
			height = M.height,
			row = M.row,
			col = M.col,
			style = "minimal",
			zindex = 250,
			focusable = false,
		})
		vim.wo[M.win].wrap = false
		vim.wo[M.win].winblend = vim.o.pumblend
		vim.wo[M.win].cursorlineopt = "line"
		vim.api.nvim_win_set_hl_ns(M.win, M.ns)
	else
		vim.api.nvim_win_set_config(
			M.win,
			{ relative = "editor", width = M.width, height = M.height, row = M.row, col = M.col }
		)
	end
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

function M.render_selected_line()
	vim.wo[M.win].cursorline = false
	if M.selected ~= -1 then
		vim.wo[M.win].cursorline = true
		local word, kind, menu = unpack(M.items[M.selected + 1])
		local has_kind = kind ~= "" and kind:sub(1, 1) ~= " "
		local has_menu = menu ~= "" and menu:sub(1, 1) ~= " "
		if has_kind then
			vim.api.nvim_buf_set_extmark(
				M.buf,
				M.ns,
				M.selected,
				#word,
				{ end_col = #kind + #word, hl_group = "PmenuKindSel" }
			)
		end
		if has_menu then
			vim.api.nvim_buf_set_extmark(
				M.buf,
				M.ns,
				M.selected,
				#word + #kind,
				{ end_col = #menu + #word + #kind, hl_group = "PmenuExtraSel" }
			)
		end
		if M.width > #word + #kind + #menu and (has_kind or has_menu) then
			local end_hl_group = has_menu and "PmenuExtraSel" or "PmenuKindSel"
			vim.api.nvim_buf_set_extmark(
				M.buf,
				M.ns,
				M.selected,
				#word + #kind + #menu,
				{ end_row = M.selected + 1, end_col = 0, strict = false, hl_group = end_hl_group, hl_eol = true }
			)
		end
		vim.api.nvim_win_set_cursor(M.win, { M.selected + 1, 0 })
	end
end

function M.render()
	M.init_buffer()
	M.init_window()
	vim.api.nvim_buf_set_lines(
		M.buf,
		0,
		-1,
		false,
		vim.tbl_map(function(item)
			return item[1] .. item[2] .. item[3]
		end, M.items)
	)
	M.render_selected_line()
	M.render_scrollbar()
end

function M.exit()
	vim.api.nvim_win_close(M.win, true)
	M.win = -1
	M.buf = -1
end

function M.format(items)
	local word_len, kind_len, menu_len = 0, 0, 0
	for _, item in ipairs(items) do
		if M.row == 0 or M.col ~= 0 then
			item[1] = " " .. item[1]
		end
		word_len = math.max(word_len, vim.api.nvim_strwidth(item[1]))
		kind_len = math.max(kind_len, vim.api.nvim_strwidth(item[2]))
		menu_len = math.max(menu_len, vim.api.nvim_strwidth(item[3]))
	end
	local has_kind = kind_len == 0 and 0 or 1
	local has_menu = menu_len == 0 and 0 or 1
	local padding = #M.items > M.height and 3 or 2
	for _, item in ipairs(items) do
		item[1] = item[1]
			.. string.rep(" ", word_len - vim.api.nvim_strwidth(item[1]))
			.. (" "):rep(has_kind + has_menu - has_kind * has_menu)
			.. (" "):rep(padding * (1 - has_kind) * (1 - has_menu))
		item[2] = item[2]
			.. string.rep(" ", kind_len - vim.api.nvim_strwidth(item[2]))
			.. (" "):rep(has_menu * has_kind)
			.. (" "):rep(padding * (1 - has_menu) * has_kind)
		item[3] = item[3] .. string.rep(" ", menu_len - vim.api.nvim_strwidth(item[3])) .. (" "):rep(padding * has_menu)
	end
end

function M.on_show(...)
	M.items, M.selected, M.row, M.col, M.grid = ...
	M.height = vim.o.pumheight == 0 and 1000 or vim.o.pumheight
	M.height = math.min(#M.items, M.height, math.max(vim.o.lines - M.row - 1, M.row))
	if M.grid == -1 then
		M.row = vim.o.lines - vim.o.cmdheight - M.height
	elseif M.height > vim.o.lines - M.row - 1 then
		M.row = M.row - M.height
	else
		M.row = M.row + 1
	end
	if M.grid == 1 and M.col ~= 0 then
		M.col = M.col - 1
	end
	M.format(M.items)
	M.width = math.min(vim.api.nvim_strwidth(table.concat(M.items[1])), vim.o.columns - M.col)
	M.width = math.max(M.width, vim.o.pumwidth)
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
	M.ns = vim.api.nvim_create_namespace("ed-pumenu")
	vim.api.nvim_set_hl(M.ns, "Normal", { link = "Pmenu" })
	vim.api.nvim_set_hl(M.ns, "CursorLine", { link = "PmenuSel" })
	M.old_pum_getpos = vim.fn.pum_getpos
	vim.fn.pum_getpos = function()
		if M.win == -1 or not vim.api.nvim_win_is_valid(M.win) then
			return {}
		else
			return {
				height = M.height,
				width = M.width,
				row = M.row,
				col = M.col,
				size = #M.items,
				scrollbar = #M.items > M.height,
			}
		end
	end
end

return M
