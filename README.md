# Cmdline Editor Plugin for Neovim

This plugin allows to edit the cmdline like you would a normal buffer, in a
similar way as the cmdwindow (Ctrl-F in cmd mode). However it allows you to
keep the preview features ('incsearch', 'inccommand') when inserting characters
in the cmdline (as opposed to the cmdwindow).

This plugin disable the default cmdline and popup menu so there might be some
difference in behaviour (cases that I might no have encountered and replicated)

## Features

- **Command Editing**: Edit your cmdline like a normal buffer.
- **Commandline features** : Keep almost all the cmdline features (no block mode).
- **Command Line History Navigation**: Navigate through previously entered
  commands with ease like in the cmdwindow and reuse them.

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
