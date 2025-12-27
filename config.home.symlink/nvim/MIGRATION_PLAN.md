---
name: Neovim Setup (Improved)
overview: Modular Pure Lua Neovim config with environment detection and essential plugins first, progressively adding features.
todos:
  - id: env-detection
    content: Create environment detection module (core/env.lua)
    status: completed
  - id: core-options
    content: Port core options to Lua (core/options.lua)
    status: completed
  - id: lazy-bootstrap
    content: Setup lazy.nvim bootstrap (core/lazy.lua)
    status: completed
  - id: init-orchestration
    content: Create main init.lua with conditional loading
    status: completed
  - id: plugin-editing
    content: Setup text editing plugins (surround, commentary, repeat)
    status: completed
  - id: plugin-git
    content: Setup git plugins (fugitive, rhubarb, gitsigns) - terminal only
    status: completed
  - id: plugin-fzf
    content: Setup fzf.vim with ripgrep integration - terminal only
    status: completed
  - id: plugin-tree
    content: Setup nvim-tree file explorer - terminal only
    status: completed
  - id: plugin-statusline
    content: Setup lualine statusline - terminal only
    status: completed
  - id: plugin-ui
    content: Setup UI plugins (smoothie, diminactive) - terminal only
    status: completed
  - id: core-keymaps
    content: Port essential keymaps (universal + terminal-specific)
    status: completed
  - id: treesitter
    content: Setup treesitter for syntax highlighting - terminal only
    status: pending
  - id: lsp-setup
    content: Setup native LSP (typescript, lua) - terminal only
    status: pending
  - id: completion
    content: Setup nvim-cmp completion - terminal only
    status: pending
  - id: colorscheme
    content: Setup colorscheme - terminal only
    status: pending
  - id: custom-utils
    content: Port custom utility functions from old config (window.lua done)
    status: in_progress
---

# Neovim Setup - Modular Migration Plan

## Context

Migrating from legacy setup (Vimscript + Packer + COC) to modern setup (Pure Lua + lazy.nvim + Native LSP) with smart environment detection.

**Key principle**: Start with essentials, get something working quickly, iterate.

---

## Foundation

Get the bare minimum working first.

### Environment Detection Module
**File**: [`config.home.symlink/nvim/lua/core/env.lua`](config.home.symlink/nvim/lua/core/env.lua)

Detect execution environment early:
- Check for `vim.g.vscode` (set by both VSCode and Cursor)
- If set → GUI environment (minimal config)
- If not set → Terminal environment (full config)

Export environment flag:
```lua
return {
  is_vscode = vim.g.vscode ~= nil,
}
```

---

### Core Options Module
**File**: [`config.home.symlink/nvim/lua/core/options.lua`](config.home.symlink/nvim/lua/core/options.lua)

Port essential settings from [`dotfilesold/config/nvim/startup/options.vim`](dotfilesold/config/nvim/startup/options.vim):
- Line numbers, clipboard integration (`unnamedplus`)
- Indentation (expandtab, shiftwidth=2, tabstop=4)
- Search (ignorecase, smartcase)
- UI (scrolloff, laststatus, etc.)
- Files (undofile, noswapfile, nobackup)
- **Load for all environments** (GUI and terminal)

---

### Plugin Manager Bootstrap
**File**: [`config.home.symlink/nvim/lua/core/lazy.lua`](config.home.symlink/nvim/lua/core/lazy.lua)

Setup lazy.nvim:
- Auto-install on first run
- Configure lazy options (performance, dev mode)
- Set plugin directory
- **Load for all environments**, but plugin list will differ

---

### Init Entry Point
**File**: [`config.home.symlink/nvim/init.lua`](config.home.symlink/nvim/init.lua)

Main orchestration:
```lua
-- 1. Detect environment first
local env = require('core.env')

-- 2. Core settings (all environments)
require('core.options')

-- 3. Bootstrap lazy.nvim
require('core.lazy')

-- 4. Load plugins (environment-aware)
if env.is_vscode then
  require('plugins.minimal')  -- Just keymaps & text objects
else
  require('plugins')  -- Full plugin suite
end

-- 5. Core keymaps (all environments)
require('core.keymaps')

-- 6. Terminal-only config
if not env.is_vscode then
  require('config.lsp')
  require('config.autocmds')
end
```

---

## Essential Plugins (Get Working Fast)

Start with plugins that give immediate value. Load conditionally based on environment.

### Text Manipulation (ALL environments)
**File**: [`config.home.symlink/nvim/lua/plugins/editing.lua`](config.home.symlink/nvim/lua/plugins/editing.lua)

Core text editing plugins:
- **`vim-surround`** - change/delete surroundings (cs, ds, ys)
- **`vim-commentary`** - comment toggling (gcc, gc + motion)
  - Note: Neovim 0.10+ has built-in commenting, but vim-commentary still popular
  - Alternative: `Comment.nvim` (Pure Lua)
- **`vim-repeat`** - repeat plugin actions with `.`

**Load in**: All environments (these enhance core editing)

---

### Git Integration (Terminal only)
**File**: [`config.home.symlink/nvim/lua/plugins/git.lua`](config.home.symlink/nvim/lua/plugins/git.lua)

Essential git workflow:
- **`vim-fugitive`** - Git wrapper (`:Git`, `:Gread`, `:Gdiffsplit`)
- **`vim-rhubarb`** - GitHub integration for `:Gbrowse`
- **`gitsigns.nvim`** - Git signs in gutter, hunk navigation
  - Keymaps: `]g`/`[g` (next/prev hunk), `<space>hs` (stage), `<space>hu` (undo)

**Load in**: Terminal only (VSCode/Cursor has built-in git)

---

### Fuzzy Finder (Terminal only)
**File**: [`config.home.symlink/nvim/lua/plugins/fzf.lua`](config.home.symlink/nvim/lua/plugins/fzf.lua)

Using fzf.vim (fast, familiar from old config):
- **`fzf`** - Core fuzzy finder binary
- **`fzf.vim`** - Vim integration

Key commands to setup:
- `:GFiles` / `:Files` - file finder
- `:Rg` / `:Ag` - grep search (use ripgrep)
- `:Buffers` - buffer list
- `:History:` - command history

Port mappings from [`dotfilesold/config/nvim/startup/leader_mappings.vim`](dotfilesold/config/nvim/startup/leader_mappings.vim):
- `<c-t>` → `:GFiles`
- `<space>fa` → `:Files`
- `<space>fw` → `:Rg` (ripgrep)
- `\b` / `1b` → `:Buffers`

**Load in**: Terminal only (VSCode/Cursor has Cmd+P)

---

### File Explorer (Terminal only)
**File**: [`config.home.symlink/nvim/lua/plugins/tree.lua`](config.home.symlink/nvim/lua/plugins/tree.lua)

Using nvim-tree (simpler, faster):
- File tree with git status
- Keymaps: `1n` (toggle), `<space>nf` (find current file)
- Show hidden files option

**Load in**: Terminal only (VSCode/Cursor has built-in explorer)

---

### Statusline (Terminal only)
**File**: [`config.home.symlink/nvim/lua/plugins/statusline.lua`](config.home.symlink/nvim/lua/plugins/statusline.lua)

Using lualine (simple, fast):
- Show mode, filename, git branch
- LSP diagnostics count
- File format, encoding
- Minimal config, fast startup

**Load in**: Terminal only (VSCode/Cursor has its own statusline)

---

### Visual Enhancements (Terminal only)
**File**: [`config.home.symlink/nvim/lua/plugins/ui.lua`](config.home.symlink/nvim/lua/plugins/ui.lua)

UI improvements:
- **`vim-smoothie`** or **`vim-smoothscroll`** - smooth scrolling
- **`vim-diminactive`** - dim inactive windows
  - Alternative: `shade.nvim` (Pure Lua)

**Load in**: Terminal only (not needed in VSCode/Cursor)

---

### Essential Keymaps
**File**: [`config.home.symlink/nvim/lua/core/keymaps.lua`](config.home.symlink/nvim/lua/core/keymaps.lua)

Port critical mappings from [`dotfilesold/config/nvim/startup/leader_mappings.vim`](dotfilesold/config/nvim/startup/leader_mappings.vim):

**Universal keymaps (ALL environments)**:
- `<space><space>` - save file (`:update`)
- `j` / `k` - move by display lines (gj/gk)
- Window navigation: `gh`, `gj`, `gk`, `gl`
- `\w` / `\q` - close window
- Basic surround/commentary keymaps (if plugins loaded)

**Terminal-only keymaps**:
- `<c-t>` - fuzzy file finder (fzf)
- `<space>gs` - Git status
- `<space>gd` - Git diff
- `<space>gl` - Git log
- `<space>bd` - Buffer delete
- `<space>fa` / `<space>fw` - Find file / grep
- `1n` - Toggle file tree
- All other plugin-dependent mappings

**Modularization**: Consider splitting into:
- `lua/core/keymaps.lua` - universal keymaps
- `lua/config/keymaps-plugins.lua` - plugin-specific keymaps

---

## Syntax & Intelligence

Add language intelligence after essentials are working.

### Treesitter (Terminal only, maybe Cursor)
**File**: [`config.home.symlink/nvim/lua/plugins/treesitter.lua`](config.home.symlink/nvim/lua/plugins/treesitter.lua)

Port from [`dotfilesold/config/nvim/lua/init.lua`](dotfilesold/config/nvim/lua/init.lua):
- Install parsers: typescript, javascript, lua, vim, python, go, markdown
- Enable highlighting, incremental selection
- Fold configuration (foldmethod=expr, foldexpr=nvim_treesitter#foldexpr)

**Load in**: Terminal only

---

### LSP Foundation (Terminal only)
**File**: [`config.home.symlink/nvim/lua/config/lsp/init.lua`](config.home.symlink/nvim/lua/config/lsp/init.lua)

Replace COC with native LSP:
- `nvim-lspconfig` - LSP configurations
- Setup servers: `typescript-tools.nvim` (or `tsserver`), `lua_ls`
- Basic keymaps: `gd` (definition), `gr` (references), `K` (hover), `<space>cd` (definition)

**Modularization**:
- `lua/config/lsp/init.lua` - main LSP setup
- `lua/config/lsp/servers/` - per-server configs (typescript.lua, lua.lua, etc.)
- `lua/config/lsp/keymaps.lua` - LSP keybindings

**Load in**: Terminal only (VSCode/Cursor has its own LSP)

---

### Auto-completion (Terminal only)
**File**: [`config.home.symlink/nvim/lua/plugins/cmp.lua`](config.home.symlink/nvim/lua/plugins/cmp.lua)

Setup nvim-cmp:
- Sources: LSP, buffer, path, snippets
- Keybindings: `<Tab>` accept, `<C-n>/<C-p>` navigate
- Snippet engine: LuaSnip (modern) or compatibility with old UltiSnips

**Load in**: Terminal only

---

## Appearance & Polish

Make it look good after functionality is solid.

### Colorscheme
**File**: [`config.home.symlink/nvim/lua/plugins/theme.lua`](config.home.symlink/nvim/lua/plugins/theme.lua)

Legacy used `darktooth` from `nvcode-color-schemes.vim`:
- **Option 1**: Port darktooth
- **Option 2**: Modern alternative (tokyonight, catppuccin, gruvbox.nvim)

**Load in**: Terminal only (VSCode/Cursor has its own theme)

---

### Additional UI Enhancements
**File**: [`config.home.symlink/nvim/lua/plugins/ui.lua`](config.home.symlink/nvim/lua/plugins/ui.lua)

- `nvim-colorizer.lua` - highlight color codes
- `vim-mark` - highlight interesting words (`<space>hi`)
- `indent-blankline.nvim` - indentation guides (if desired)

**Load in**: Terminal only

---

## Advanced Features

Add as needed, lower priority.

### Language-Specific Plugins
**File**: [`config.home.symlink/nvim/lua/plugins/languages.lua`](config.home.symlink/nvim/lua/plugins/languages.lua)

Port from [`dotfilesold/config/nvim/lua/plugins.lua`](dotfilesold/config/nvim/lua/plugins.lua) as needed:
- **Markdown**: `vim-markdown`, `markdown-preview.nvim`
- **Go**: `vim-go`
- **CSS/SCSS**: syntax plugins
- Others: csv, etc.

Only install if actively using these languages.

---

### Utility Plugins
**File**: [`config.home.symlink/nvim/lua/plugins/utils.lua`](config.home.symlink/nvim/lua/plugins/utils.lua)

Nice-to-have plugins:
- `vim-sleuth` - auto-detect indent style
- `vim-pasta` - smart paste indentation
- `vim-unimpaired` - bracket mappings (`]q`, `[q`, etc.)
- `vim-visual-star-search` - `*` in visual mode

---

### Custom Utilities
**Files**:
- [`config.home.symlink/nvim/lua/utils/init.lua`](config.home.symlink/nvim/lua/utils/init.lua)
- [`config.home.symlink/nvim/lua/utils/window.lua`](config.home.symlink/nvim/lua/utils/window.lua)
- [`config.home.symlink/nvim/lua/utils/git.lua`](config.home.symlink/nvim/lua/utils/git.lua)

Port custom functions from:
- [`dotfilesold/config/nvim/lua/utils.lua`](dotfilesold/config/nvim/lua/utils.lua)
- [`dotfilesold/config/nvim/autoload/utils.vim`](dotfilesold/config/nvim/autoload/utils.vim)

Functions like window movement, buffer management, cursor ping, etc.

---

### Remaining Keymaps & Abbrevs
Port as needed:
- Advanced search/find helpers
- Fold navigation
- Snippets conversion (UltiSnips → LuaSnip)
- Abbreviations

---

## Project Structure

Final modular structure:

```
config.home.symlink/nvim/
├── init.lua                          # Main entry point with env detection
├── lua/
│   ├── core/                         # Core functionality (all environments)
│   │   ├── env.lua                   # Environment detection
│   │   ├── options.lua               # Core Vim options
│   │   ├── keymaps.lua               # Universal keymaps
│   │   └── lazy.lua                  # Plugin manager bootstrap
│   ├── plugins/                      # Plugin specifications for lazy.nvim
│   │   ├── init.lua                  # Full plugin list (terminal)
│   │   ├── minimal.lua               # Minimal plugin list (GUI)
│   │   ├── editing.lua               # Text manipulation (surround, commentary)
│   │   ├── git.lua                   # Git plugins (fugitive, gitsigns)
│   │   ├── fzf.lua                   # Fuzzy finder
│   │   ├── tree.lua                  # File explorer (nvim-tree)
│   │   ├── statusline.lua            # Lualine config
│   │   ├── ui.lua                    # UI enhancements (smoothie, diminactive)
│   │   ├── treesitter.lua            # Treesitter config
│   │   ├── cmp.lua                   # Completion
│   │   ├── theme.lua                 # Colorscheme
│   │   ├── languages.lua             # Language-specific plugins
│   │   └── utils.lua                 # Utility plugins
│   ├── config/                       # Advanced configuration (terminal only)
│   │   ├── lsp/                      # LSP configuration
│   │   │   ├── init.lua              # LSP setup
│   │   │   ├── keymaps.lua           # LSP keybindings
│   │   │   └── servers/              # Per-server configs
│   │   │       ├── typescript.lua
│   │   │       └── lua.lua
│   │   ├── autocmds.lua              # Auto-commands
│   │   └── keymaps-plugins.lua       # Plugin-specific keymaps
│   └── utils/                        # Custom utility functions
│       ├── init.lua
│       ├── window.lua
│       └── git.lua
```

---

## Implementation Order

Start here and work down:

- **Foundation** - Get init.lua loading with env detection
- **Essential Plugins** - Text editing, git, fzf, tree, statusline
  - These give immediate productivity value
  - Test in both Cursor and Terminal
- **Syntax & Intelligence** - Treesitter, LSP, completion
  - Terminal only, adds language smarts
- **Appearance & Polish** - Theme, UI enhancements
  - Make it look good
- **Advanced Features** - Language plugins, utilities, remaining keymaps
  - As needed, lower priority

---

## Testing Checklist

After each phase:
- Test in terminal Neovim
- Test in VSCode/Cursor (verify minimal config loads)
- Verify startup time: < 100ms (VSCode/Cursor), < 200ms (Terminal)
- Check that plugins only load in intended environments

---

## Discussion Points

1. **Commentary**: Use `vim-commentary` or switch to `Comment.nvim` (Pure Lua)?
2. **Diminactive**: Keep `vim-diminactive` or use `shade.nvim` (Pure Lua)?