# Cmdline Editor Plugin for Neovim

https://github.com/user-attachments/assets/ce891412-29a7-486b-aa9d-20099a972514

This plugin allows you to edit the cmdline like you would a normal buffer, in a
similar way as the cmdwindow (Ctrl-F in cmd mode). However, unlike the cmdwindow
you keep the preview features ('incsearch', 'inccommand') when inserting in the
cmdline.

This plugin disables the default cmdline and popup menu so there might be some
differences in behaviour (cases that I might not have encountered and replicated).

As a nice bonus you can put the cmdline wherever you want. (Even in its default position !)

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
			cmdline = {
				keymaps = { edit = "<ESC>", execute = "<CR>", close = "<C-C>" },
				win_config = function()
					return {
						relative = "editor",
						zindex = 250,
						row = vim.o.lines - vim.o.cmdheight,
						col = 0,
						style = "minimal",
						width = vim.o.columns,
						height = 1,
					}
				end,
			},
			-- You enter normal mode in the cmdline with edit, execute a
			-- command from normal mode with execute and close the cmdline in
			-- normal mode with close
			-- The keymaps fields also accept list of keymaps
			-- cmdline = { keymaps = { close = { "<C-C>" , "q" } } },
		})
	end,
}
```

## Usage

Popupmenu height, width and blend options can be defined as usual with set pumwidth (vim.o.pumwidth) ...

If you want to use a multiple characters keymap for "edit" ("ij" for example), all characters ("i") but the last will still
be inserted in the command line before entering "normal" mode. To avoid that, you might want to set the following keymap rather
than passing it to the setup function (adapt it to the number of characters you actually use) :

```lua
vim.keymap.set("c", "ij", function()
	require("ed-cmd.cmdline").enter_edit()
	vim.schedule(function()
		vim.cmd("silent norm lxh")
	end)
end, {})
```

You can choose to position the cmdline in a specific place through the win_config option. The win_config will also be called
to set the cmdline window config on VimResize event. So, if you want the cmdline to keep a relative position (centered for example)
you can just define a win_config that computes a position dynamically.

```lua
centered_win_config = function()
	return {
		relative = "editor",
		width = math.ceil(vim.o.columns / 3),
		row = math.floor(vim.o.lines * 0.2),
		col = math.floor(vim.o.columns / 3),
		height = 2,
		style = "minimal",
		border = "single",
		zindex = 240 --popupmenu is 250
	}
end
```

## License

This project is licensed under the MIT License.
