# nvchecker.nvim

A Neovim plugin that automatically runs [nvchecker](https://github.com/lilydjwg/nvchecker) on configuration files and displays results in a floating window.

## Features

- 🚀 **Auto-run on save** - Automatically runs nvchecker when saving `*nvchecker.toml` files  
- 💬 **Floating output** - Shows results in a clean floating window with syntax highlighting
- ⚡ **Async execution** - Non-blocking nvchecker execution with timeout protection
- 🎯 **Smart detection** - Only activates on files ending with `nvchecker.toml`
- ⌨️ **Keymaps & commands** - Manual execution via commands and keybindings

## Installation

### With LazyVim

```lua
return {
  {
    "envolution/nvchecker.nvim",
    config = function()
      require("nvchecker").setup()
    end,
    ft = "toml",
    cmd = { "NvCheckerRun", "NvCheckerToggle" },
  }
}
```

### With lazy.nvim

```lua
{
  "envolution/nvchecker.nvim",
  config = true,
  ft = "toml",
}
```

### With packer.nvim

```lua
use {
  "envolution/nvchecker.nvim",
  config = function()
    require("nvchecker").setup()
  end,
  ft = "toml",
}
```

## Requirements

- Neovim >= 0.8.0
- [nvchecker](https://github.com/lilydjwg/nvchecker) installed and available in PATH

Install nvchecker:

```bash
pip install nvchecker
```

## Usage

### Automatic

- Open any file named `*nvchecker.toml` (e.g., `.nvchecker.toml`, `appname-nvchecker.toml`, `nvchecker.toml`)
- Save the file - nvchecker runs automatically
- Results appear in a floating window

### Manual

- `:NvCheckerRun` - Run nvchecker on current file
- `<leader>nr` - Same as above (in nvchecker.toml files)
- `:NvCheckerToggle` - Toggle auto-run on save

## Configuration

```lua
require("nvchecker").setup({
  auto_run = true,                -- Auto-run on save
  show_success_message = true,    -- Show success notifications  
  timeout = 30000,                -- Timeout in milliseconds (30s)
  keyfile = /path/to/keyfile.toml -- NVChecker Keyfile
  window = {
    height = 10,                  -- Output window height
    border = "rounded"            -- Border style: "rounded", "single", "double", etc.
  }
})
```

## Example

1. Create a file named `nvchecker.toml`:

```toml
[github]
source = "github"
github = "neovim/neovim"

[pypi]
source = "pypi" 
pypi = "requests"
```

2. Save the file - nvchecker runs automatically
3. View results in the floating window

## Commands

| Command | Description |
|---------|-------------|
| `:NvCheckerRun` | Run nvchecker on current file |
| `:NvCheckerToggle` | Toggle auto-run feature |

## Keymaps

| Key | Mode | Description |
|-----|------|-------------|
| `<leader>nr` | Normal | Run nvchecker (nvchecker.toml files only) |

## License

BSD-3-Clause
