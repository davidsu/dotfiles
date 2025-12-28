# File Split Pattern for VSCode/Terminal Compatibility

## Strategy

Split configuration into base (universal) and `_terminal.lua` (terminal-only) files.

## Pattern

### Core Files (options, keymaps, etc.)

**Base file** (`file.lua`):
- Contains universal settings that work in both VSCode and terminal
- Defaults optimized for VSCode (since it has more built-in features)
- Conditionally requires `_terminal.lua` at the end

**Terminal file** (`file_terminal.lua`):
- Contains terminal-specific overrides and additions
- Only loaded in terminal Neovim
- No early return needed (loaded conditionally by base file)
- **Note**: Use underscore, not dot (Lua require treats dots as directory separators)

### Plugin Files

**Terminal-only** (`plugin.lua`):
- Early return at top: `if env.is_vscode then return {} end`
- Entire plugin skipped in VSCode

**Universal** (`plugin.lua`):
- No env check
- Loads in all environments

## Examples

### Core: options.lua + options_terminal.lua

```lua
-- options.lua (base)
opt.number = false        -- VSCode has its own line numbers
opt.laststatus = 0        -- VSCode has its own statusbar

if not env.is_vscode then
  require('core.options_terminal')  -- Note: underscore, not dot
end
```

```lua
-- options_terminal.lua
opt.number = true         -- Show line numbers in terminal
opt.laststatus = 2        -- Show statusbar in terminal
```

### Core: keymaps.lua + keymaps_terminal.lua

```lua
-- keymaps.lua (base)
map('n', '<C-h>', '<cmd>wincmd h<cr>')  -- Works in both

if not env.is_vscode then
  require('core.keymaps_terminal')  -- Note: underscore, not dot
end
```

```lua
-- keymaps_terminal.lua
map('n', 'gh', function() win_utils.win_move('h') end)  -- Terminal-only
map('n', '+', function() win_utils.win_size('+') end)   -- Terminal-only
```

### Plugin: Terminal-only

```lua
-- plugins/git.lua
local env = require('core.env')

if env.is_vscode then
  return {}
end

return {
  { 'tpope/vim-fugitive' }
}
```

### Plugin: Universal

```lua
-- plugins/editing.lua
return {
  { 'tpope/vim-surround' }
}
```

## Current Implementation

### Core Files
- ✅ `options.lua` + `options_terminal.lua`
- ✅ `keymaps.lua` + `keymaps_terminal.lua`
- `env.lua` - No split needed (just detection)
- `lazy.lua` - No split needed (plugin manager bootstrap)

### Plugin Files
- ✅ `editing.lua` - Universal (no early return)
- ✅ `git.lua` - Terminal-only (early return)
- ✅ `fzf.lua` - Terminal-only (early return)
- ✅ `tree.lua` - Terminal-only (early return)
- ✅ `statusline.lua` - Terminal-only (early return)
- ✅ `ui.lua` - Terminal-only (early return)
- ✅ `unimpaired.lua` - Terminal-only (early return)

## Benefits

1. **Clean separation**: Clear what runs where
2. **No conditionals in code**: Main files stay clean
3. **Easy to extend**: Add terminal features to `.terminal.lua`
4. **Consistent pattern**: Same approach across all files
5. **Performance**: VSCode doesn't load terminal-only code

## Guidelines

### When to Split
- **Split** if feature doesn't work or conflicts in VSCode
- **Don't split** if feature works identically in both

### What Requires _terminal.lua
- Custom keymaps (FZF, window resizing, custom navigation)
- UI options (statusline, line numbers, showcmd)
- Terminal-specific utilities

### What Stays Universal
- Basic vim motions and options
- Clipboard and file settings
- Simple window commands that VSCode supports

