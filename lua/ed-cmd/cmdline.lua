local ENTER = vim.api.nvim_replace_termcodes("<cr>", true, true, true)
local ESC = vim.api.nvim_replace_termcodes("<esc>", true, true, true)

local M = {
	intercept = false,
	buf = -1,
	win = -1,
	curr_win = -1,
	cmd = nil,
	pos = 0,
	firtc = nil,
	prompt = nil,
	keymaps = {},
	history = {},
}

function M.set_cmdline_keymaps(mode, list_lhs, rhs, opts)
	for _, lhs in ipairs(list_lhs) do
		vim.keymap.set(mode, lhs, rhs, opts)
	end
end

function M.init_buf()
	if vim.api.nvim_buf_is_loaded(M.buf) then
		return
	end
	M.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[M.buf].bufhidden = "wipe"
	vim.bo[M.buf].buftype = "nofile"
	vim.api.nvim_buf_set_name(M.buf, "cmdline")
	M.exit_autocmd = vim.api.nvim_create_autocmd({ "BufLeave", "BufHidden" }, { buffer = M.buf, callback = M.exit })
	M.set_cmdline_keymaps("n", M.keymaps.close, M.exit, { buffer = M.buf, silent = true, noremap = true })
	M.set_cmdline_keymaps("n", M.keymaps.execute, M.exe, { buffer = M.buf, silent = true, noremap = true })
	vim.api.nvim_create_autocmd({ "InsertEnter" }, {
		buffer = M.buf,
		callback = function()
			vim.api.nvim_feedkeys(ESC, "nt", false)
			M.exit_edit()
		end,
	})
end

function M.win_config()
	return {
		relative = "editor",
		zindex = 250,
		row = vim.o.lines - vim.o.cmdheight,
		col = 0,
		style = "minimal",
		width = vim.o.columns,
		height = 1,
	}
end

function M.init_win()
	if not vim.api.nvim_win_is_valid(M.win) then
		M.curr_win = vim.api.nvim_get_current_win()
		M.win = vim.api.nvim_open_win(M.buf, false, M.win_config())
		vim.wo[M.win].winfixbuf = true
		vim.wo[M.win].virtualedit = "onemore"
		vim.wo[M.win].wrap = false
		vim.api.nvim_win_set_hl_ns(M.win, M.ns)
		vim.cmd("echon")
	end
end

function M.get_history()
	local len = vim.fn.histnr(M.firstc)
	local history = {}
	for i = 1, len do
		local cmd = vim.fn.histget(M.firstc, i)
		if cmd ~= "" then
			table.insert(history, vim.fn.histget(M.firstc, i))
		end
	end
	return history
end

function M.set_history()
	local history = M.get_history()
	vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, history)
end

function M.render()
	if not M.firstc or not M.prompt then
		return
	end
	M.init_buf()
	if not vim.api.nvim_win_is_valid(M.win) then
		M.init_win()
		if M.prompt and M.prompt ~= "" then
			vim.api.nvim_buf_set_lines(M.buf, 0, 0, false, { M.cmd })
			vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 0, {
				virt_text = { { M.prompt, "MsgArea" } },
				virt_text_pos = "inline",
				right_gravity = false,
			})
			vim.api.nvim_win_set_cursor(M.win, { 1, M.pos })
		elseif M.firstc and M.firstc ~= "" then
			M.set_history()
			vim.wo[M.win].statuscolumn = "%#MsgArea#" .. M.firstc
			vim.api.nvim_buf_set_lines(M.buf, -1, -1, false, { (" "):rep(M.indent) .. M.cmd })
			vim.api.nvim_win_set_cursor(M.win, { vim.fn.line("$", M.win), M.indent + M.pos })
		end
	else
		vim.api.nvim_buf_set_lines(
			M.buf,
			vim.fn.line(".", M.win) - 1,
			vim.fn.line(".", M.win),
			false,
			{ (" "):rep(M.indent) .. M.cmd }
		)
		vim.api.nvim_win_set_cursor(M.win, { vim.fn.line(".", M.win), M.indent + M.pos })
	end
	vim.api.nvim__redraw({ flush = true, cursor = true, win = M.win })
end

function M.enter_edit()
	M.intercept = true
	vim.api.nvim_feedkeys(ESC, "nt", false)
	vim.api.nvim_set_current_win(M.win)
	M.pos = M.pos > 0 and M.pos - 1 or M.pos
	local line = vim.fn.line(".", M.win)
	vim.schedule(function()
		if vim.api.nvim_win_is_valid(M.win) then
			vim.api.nvim_win_set_cursor(M.win, { line, M.pos })
		end
	end)
end

function M.exit_edit()
	local curpos = vim.api.nvim_win_get_cursor(M.win)
	M.pos = curpos[2]
	M.cmd = vim.api.nvim_get_current_line()
	vim.api.nvim_del_autocmd(M.exit_autocmd)
	vim.api.nvim_set_current_win(M.curr_win)
	M.exit_autocmd = vim.api.nvim_create_autocmd({ "BufLeave", "BufHidden" }, { buffer = M.buf, callback = M.exit })
	vim.api.nvim_input(M.firstc)
end

function M.exe()
	M.exit_edit()
	vim.api.nvim_input(ENTER)
end

function M.exit()
	if vim.api.nvim_win_is_valid(M.win) then
		vim.api.nvim_win_close(M.win, true)
	end
	M.cmd = nil
	M.pos = 0
	M.firstc = nil
	M.prompt = nil
	M.win = -1
	M.buf = -1
	M.history = {}
	M.intercept = false
end

function M.reemit()
	vim.fn.setcmdline(M.cmd, M.pos + 1)
	M.render()
	M.intercept = false
end

function M.search_handler(event, ...)
	if event == "msg_show" then
		local kind, _, _ = ...
		if kind == "return_prompt" then
			vim.api.nvim_input("<cr>")
		end
	end
end

function M.on_show(...)
	if M.intercept then
		M.reemit()
		return
	end
	local content
	content, M.pos, M.firstc, M.prompt, M.indent, _ = ...
	local cmd = ""
	for _, chunk in ipairs(content) do
		cmd = cmd .. chunk[2]
	end
	if M.cmd == cmd then
		return
	end
	M.cmd = cmd
	M.render()
end

function M.on_pos(...)
	local pos, _ = ...
	M.pos = pos
	M.render()
end

function M.on_special_char(...)
	local c, shift, level = ...
	M.cmd = M.cmd:sub(1, M.pos) .. c .. M.cmd:sub(M.pos + 1)
	M.render()
end

function M.on_hide()
	-- You can't go to edit mode when in a prompt
	if (M.prompt and M.prompt ~= "") or not M.intercept then
		M.exit()
	end
end

function M.check_win_config(win_config)
	if not win_config then
		return false
	end
	local _, config = pcall(win_config)
	local ok, win = pcall(vim.api.nvim_open_win, 0, false, config)
	if ok then
		vim.api.nvim_win_close(win, true)
	else
		vim.schedule(function()
			vim.notify("ed-cmd.nvim : invalid cmdline.win_config function, running with default", vim.log.levels.WARN)
		end)
	end
	return ok
end

function M.setup(opts)
	M.ns = vim.api.nvim_create_namespace("ed-cmdline")
	M.ns_search = vim.api.nvim_create_namespace("ed-cmdline-search")
	M.augroup = vim.api.nvim_create_augroup("ed-cmdline", {})
	M.keymaps.close = type(opts.keymaps.close) == "string" and { opts.keymaps.close } or opts.keymaps.close
	M.keymaps.execute = type(opts.keymaps.execute) == "string" and { opts.keymaps.execute } or opts.keymaps.execute
	local keymaps_edit = type(opts.keymaps.edit) == "string" and { opts.keymaps.edit } or opts.keymaps.edit
	M.set_cmdline_keymaps("c", keymaps_edit, M.enter_edit, { desc = "Enter cmdline edit mode" })
	M.win_config = M.check_win_config(opts.win_config) and opts.win_config or M.win_config
	vim.api.nvim_set_hl(M.ns, "NormalFloat", { link = "MsgArea" })
	vim.api.nvim_set_hl(M.ns, "Search", { link = "MsgArea" })
	vim.api.nvim_set_hl(M.ns, "CurSearch", { link = "MsgArea" })
	vim.api.nvim_set_hl(M.ns, "Substitute", { link = "MsgArea" })
	vim.api.nvim_create_autocmd("CmdlineLeave", {
		desc = "Handling hit-return prompt on search not found",
		group = M.augroup,
		callback = function()
			if vim.v.event.abort then
				return
			end
			if vim.v.event.cmdtype == "/" or vim.v.event.cmdtype == "?" then
				local pattern = vim.fn.getcmdline()
				local result = vim.fn.search(pattern, "nc")
				local cmdheight = vim.o.cmdheight
				if result == 0 then
					vim.ui_attach(M.ns_search, { ext_messages = true }, M.search_handler)
					vim.o.cmdheight = cmdheight
					vim.schedule(function()
						vim.ui_detach(M.ns_search)
						vim.api.nvim_echo({ { vim.v.errmsg, "ErrorMsg" } }, false, {})
					end)
				end
			end
		end,
	})
	vim.api.nvim_create_autocmd("VimResized", {
		desc = "ed-cmd keep its relative pos",
		group = M.augroup,
		callback = function()
			if vim.api.nvim_win_is_valid(M.win) then
				vim.api.nvim_win_set_config(M.win, M.win_config())
				M.render()
			end
		end,
	})
end

function M.handler(event, ...)
	if event == "cmdline_show" then
		M.on_show(...)
	elseif event == "cmdline_pos" then
		M.on_pos(...)
	elseif event == "cmdline_hide" then
		M.on_hide()
	elseif event == "cmdline_special_char" then
		M.on_special_char(...)
	else
		-- ignore: (cmdline_block_show, cmdline_block_append and cmdline_block_hide)cmd
		return
	end
end

return M
