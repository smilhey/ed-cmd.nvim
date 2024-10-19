local M = { enabled = false }

M.opts = {
	cmdline = { keymaps = { edit = "<ESC>", execute = "<CR>" } },
	pumenu = { max_items = 100 },
}

local cmdline = require("ed-cmd.cmdline")
local pumenu = require("ed-cmd.pumenu")

function M.setup(opts)
	opts = vim.tbl_deep_extend("force", M.opts, opts)
	cmdline.setup(opts.cmdline)
	pumenu.setup(opts.pumenu)
	M.ns = vim.api.nvim_create_namespace("ed-cmd")
	M.attach()
end

function M.attach()
	vim.ui_attach(M.ns, { ext_cmdline = true, ext_popupmenu = true }, function(event, ...)
		if event:match("cmd") ~= nil then
			cmdline.handler(event, ...)
		elseif event:match("pop") ~= nil then
			pumenu.handler(event, ...)
		end
	end)
end

return M
