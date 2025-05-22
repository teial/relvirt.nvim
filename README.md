# relvirt.nvim

A minimal Neovim plugin that displays **virtual relative line numbers** using `virt_text`, fully customizable and non-intrusive. Especially useful in buffer types or UI contexts where Neovim’s built-in `relativenumber` is ineffective, undesirable, or disabled.

## Features

- Displays **relative line numbers** as virtual text at the end of each line
- Global enable/disable toggle
- Skips lines based on:
  - Filetype
  - Proximity to cursor
  - Window space constraints
  - Blank lines (optional)
  - Cursor line (optional)
- Fully **customizable number formatting and highlighting**
- Neovim-native, no dependencies

## Commands

| Command          | Description                      |
|------------------|----------------------------------|
| `:RelvirtToggle` | Toggle virtual numbers globally  |

## Demo

*(Coming soon)*

## Requirements

- Neovim ≥ 0.11.0

## Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "yourname/relvirt.nvim",
    opts = {
        -- optional user config (defaults shown)
        show_on_blank_lines = false,
        show_on_cursor_line = true,
        min_line_distance = 1,
        space_reserve = 0,
        ignored_filetypes = {},
        format_number = function(rel)
            return { tostring(rel), "LineNr" }
        end,
    },
}
```

### With [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "yourname/relvirt.nvim",
    config = function()
        require("relvirt").setup({
            -- your options here
        })
    end,
}
```

## Example configuration

```lua
require("relvirt").setup({
    show_on_blank_lines = true,
    show_on_cursor_line = false,
    min_line_distance = 2,
    space_reserve = 4,
    ignored_filetypes = { "help", "snacks.*" },
})
```

## Example Custom Formatting

Make relative numbers signed:
```lua
format_number = function(rel)
    return { (rel > 0 and "+" or "") .. rel, "LineNr" }
end
```

Color positive and negative differently:
```lua
format_number = function(rel)
    if rel > 0 then
        return { "+" .. rel, "DiffAdd" }
    else
        return { "" .. rel, "DiffDelete" }
    end
end
```

Use arrows for up/down:
```lua
require("relvirt").setup({
    format_number = function(rel)
        local sign = rel > 0 and "↓" or "↑"
        return { sign .. math.abs(rel), "Comment" }
    end,
})
```

## Options Reference

| Option | Type | Description |
|--------|------|-------------|
| ignored_filetypes | `string[]` | Filetypes (Lua patterns) to exclude |
| space_reserve | `integer` | Reserve space at right edge to avoid overflow |
| show_on_blank_lines | `boolean` | Show number on empty lines |
| show_on_cursor_line | `boolean` | Show number on the cursor line |
| min_line_distance | `integer` | Skip lines close to cursor (≤ this number) |
| format_number | `function` | Customize number format |

## Acknowledgments

*(To be filled in)*
