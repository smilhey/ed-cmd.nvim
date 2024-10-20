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

To cancel a command, any keymap that usually worked shoud do (apart from the one you assign to edit - see below).

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
			pumenu = { max_items = 100 },
		})
	end,
}
```

## License

This project is licensed under the MIT License.
