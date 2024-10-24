# Cmdline Editor Plugin for Neovim

https://github.com/user-attachments/assets/f3633128-1e53-4585-bf63-d94e3bce8bf6

This plugin allows you to edit the cmdline like you would a normal buffer, in a
similar way as the cmdwindow (Ctrl-F in cmd mode). However unlike the cmdwindow
you keep the preview features ('incsearch', 'inccommand') when inserting the
cmdline.

This plugin disable the default cmdline and popup menu so there might be some
difference in behaviour (cases that I might not have encountered and replicated)

## Features

- **Command Editing**: Edit your cmdline like a normal buffer.
- **Commandline features** : Keep almost all the cmdline features (no block mode).
- **Command Line History Navigation**: Navigate through previously entered
  commands with ease like in the cmdwindow (hitting j and k).

To cancel a command, any keymap that previously worked should do (apart from the one you assign to edit - see below).

## Installation

### Using lazy.nvim

```lua
{
	"smilhey/ed-cmd.nvim",
	config = function()
		require("ed-cmd").setup({
			-- Those are the default options, you can just call setup({}) if you don't want to change the defaults
			cmdline = { keymaps = { edit = "<ESC>", execute = "<CR>", close = "<C-C>" } },
			-- You enter normal mode in the cmdline with edit, execute a
			-- command from normal mode with execute and close the cmdline in
			-- normal mode with close

			-- The keymaps fields also accept list of keymaps
			-- cmdline = { keymaps = { close = { "<C-C>" , "q" } } },
			pumenu = { max_items = 100 },
		})
	end,
}
```
## Usage

If you want to use a multiple characters keymap for "edit" ("ij" for example), all characters ("i") but the last will still
be inserted in the command line before entering "normal" mode. To avoid that, you might want to set the following keymap rather 
than passing it to the setup function :

```lua
vim.keymap.set("c", "ij", function()
	require("ed-cmd.cmdline").enter_edit()
	vim.schedule(function()
		vim.cmd("silent norm lxh")
	end)
end, {})
```

## License

This project is licensed under the MIT License.
