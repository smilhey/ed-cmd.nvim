# Cmdline Editor Plugin for Neovim

https://github.com/user-attachments/assets/668b1add-c25d-4c63-a07e-1fa747a7556c

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

## Installation

### Using lazy.nvim

```lua
{
	"smilhey/ed-cmd.nvim",
	config = function()
		require("ed-cmd").setup({
			-- Those are the default options, you can just call setup({}) if you don't want to change the defaults
			cmdline = { keymaps = { edit = "<ESC>", execute = "<CR>" } },
			-- You enter normal mode in the cmdline with edit and execute a command from normal mode with execute
			pumenu = { max_items = 100 },
		})
	end,
}
```

## License

This project is licensed under the MIT License.
