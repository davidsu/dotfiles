# Neovim Configuration

Modern Neovim configuration with environment detection and modular plugin system.

## Structure

```
nvim/
├── init.lua                    # Main entry point
├── lua/
│   ├── core/                   # Core functionality
│   │   ├── env.lua            # Environment detection (VSCode/Cursor vs Terminal)
│   │   ├── options.lua        # Core Vim options
│   │   ├── keymaps.lua        # Universal keymaps
│   │   └── lazy.lua           # Plugin manager bootstrap
│   ├── config/                # Feature modules
│   │   └── mru.lua            # MRU (Most Recently Used) file tracking
│   ├── plugins/               # Plugin specifications
│   │   ├── init.lua           # Plugin loader
│   │   ├── completion.lua     # Autocompletion (nvim-cmp)
│   │   ├── editing.lua        # Text editing (surround, commentary, repeat)
│   │   ├── formatting.lua     # Code formatting (conform.nvim with Prettier)
│   │   ├── git.lua            # Git integration (fugitive, gitsigns)
│   │   ├── fzf.lua            # Fuzzy finder (fzf.vim)
│   │   ├── fzf-lua.lua        # Fuzzy finder (fzf-lua for MRU)
│   │   ├── lsp.lua            # LSP configuration (TypeScript, ESLint)
│   │   ├── mason.lua          # LSP server/formatter auto-installer
│   │   ├── mru.lua            # MRU plugin spec
│   │   ├── tree.lua           # File explorer (nvim-tree)
│   │   ├── statusline.lua     # Lualine statusline
│   │   ├── ui.lua             # UI enhancements
│   │   └── unimpaired.lua     # Bracket mappings and toggles
│   └── utils/                 # Custom utility functions
│       └── window.lua         # Smart window navigation
└── MIGRATION_PLAN.md          # Full migration plan and architecture
```

## Features

### Environment Detection
- Automatically detects VSCode/Cursor vs Terminal Neovim
- Loads minimal config in VSCode/Cursor (just keymaps and text editing)
- Loads full plugin suite in terminal
- **See**: `FILE_SPLIT_PATTERN.md` for configuration split strategy

### Core Options (All Environments)
- System clipboard integration
- Smart indentation (2 spaces)
- Case-insensitive smart search
- Persistent undo
- No swap/backup files
- Ripgrep/ag integration

### Universal Keymaps (All Environments)
- `<space><space>` - Save file
- `j`/`k` - Move by display lines
- **Window Navigation:**
  - `<C-h/j/k/l>` - Simple window navigation (move between existing windows)
  - `gh`/`gj`/`gk`/`gl` - Smart navigation (auto-creates splits at edges)
  - `<C-p>` - Previous window
- **Window Resizing:**
  - `+` / `_` - Increase/decrease window size (auto-detects split orientation)
  - `≠` / `–` - Alt+= / Alt+- alternatives
  - `<space>v` / `\x` - Toggle horizontal/vertical resize mode
- `\w` - Close window
- `<space>qq` - Close all helper windows
- `\s` - Substitute with very magic
- `m,` / `sa` - Switch to alternate file (last buffer)
- `'` - Jump to mark (exact position instead of line start)
- `q` - Close help/quickfix/fugitive windows (auto-mapped in those buffers)
- `:h` - Opens help in new tab (abbreviated from `:tab help`)

### Terminal-Only Features

#### Text Editing
- vim-surround - Change/delete surroundings
- vim-commentary - Comment toggling
- vim-repeat - Repeat plugin actions
- vim-unimpaired - Bracket mappings and toggles
  - `yow` - Toggle wrap
  - `yon` - Toggle line numbers
  - `yos` - Toggle spell check
  - `]q`/`[q` - Next/prev quickfix
  - `]b`/`[b` - Next/prev buffer

#### Git Integration
- vim-fugitive - Git wrapper
- vim-rhubarb - GitHub integration
- gitsigns.nvim - Git signs in gutter
  - `]g`/`[g` - Next/prev hunk
  - `<space>hs` - Stage hunk
  - `<space>hr` - Reset hunk
  - `<space>hu` - Undo stage hunk
  - `<space>hp` - Preview hunk
  - `<space>gs` - Git status
  - `<space>gd` - Git diff
  - `gb` - Git blame

#### Fuzzy Finder (FZF)
- `<c-t>` - Find git files
- `<space>fa` - Find all files
- `<space>fw` - Grep word (ripgrep)
- `<space>fb` / `\b` / `1b` - Find buffers
- `<space>fh` - Command history
- `\a` - Ripgrep search (fullscreen with syntax-highlighted preview via bat)
- `1m` - MRU (Most Recently Used) files (fullscreen, preview on top)

#### MRU (Most Recently Used Files)
- Automatically tracks every file you open with exact cursor position
- `1m` in Neovim opens fullscreen fzf-lua with preview
- Restores cursor to exact line and column where you left off
- File-based tracking at `~/.local/share/nvim_mru.txt` (max 100 entries)
- Filters out temporary files, git buffers, help, fugitive, etc.
- Works in both terminal (via shell function) and Neovim
- **Note**: Replaces dotfilesold's PM2/Node.js server with simple Lua implementation

#### LSP (Language Server Protocol)
- Native Neovim LSP with **TypeScript** and **ESLint** support
- **Navigation:**
  - `<space>cd` / `gd` - Go to definition
  - `gD` - Go to declaration
  - `gi` - Go to implementation
  - `gr` - Find references
  - `K` - Hover documentation
- **Actions:**
  - `<space>rn` - Rename symbol
  - `<space>ca` / `<space>cf` - Code actions
  - `<space>f` - Format document (uses Prettier via conform.nvim)
- **Diagnostics:**
  - Shows both TypeScript errors AND ESLint rule violations
  - Diagnostics appear only in normal mode (not while typing in insert mode)
  - `<space>lo` - Open diagnostics list
  - `]d` / `[d` - Next/prev diagnostic
  - `<Esc>` / `<C-c>` - Close floating windows (hover, diagnostics, etc.)

#### Formatting
- Powered by **conform.nvim** with **Prettier**
- Automatically finds and uses project's Prettier config (`.prettierrc`, `prettier.config.js`)
- Uses project's `node_modules/.bin/prettier` if available, falls back to Mason-installed version
- **Auto-format on save** for TypeScript, JavaScript, JSON, CSS, HTML, Markdown, YAML
- **Manual format**: `<space>f` or `:Format`
- Works even when opening files outside current working directory (auto-detects project root)
- **Project root detection**: Walks up directory tree to find `package.json`, `.git`, etc.

#### Mason (LSP Server Management)
- **Automatic installation** of LSP servers and formatters on first Neovim startup
- **Auto-installed tools**:
  - `ts_ls` - TypeScript/JavaScript language server
  - `eslint` - ESLint language server for linting diagnostics
  - `prettier` - Code formatter
- **UI**: Run `:Mason` to see installed tools, update them, or install additional ones
- **Zero manual setup** - works out of the box on new machines
- **Per-project versions respected**: If project has tools in `node_modules`, those are used instead

#### Completion (IntelliSense)
- Powered by nvim-cmp with LSP integration
- **Popup opens automatically** as you type
- **Navigation:**
  - `<C-n>` / `<C-p>` - Next/previous completion item
  - `<C-d>` / `<C-f>` - Scroll documentation up/down
- **Accept completion:**
  - `<Tab>` - Accept highlighted item (or first item if none selected)
  - `<CR>` (Enter) - Accept only if explicitly selected
- **Close popup:**
  - `<C-e>` - Close completion menu (stays in insert mode)
  - `<Esc>` - Close and exit insert mode
- **Manual trigger:**
  - `<C-Space>` - Manually trigger completion
- Sources: LSP (highest priority), file paths, buffer words

#### File Explorer
- `1n` - Toggle file tree
- `<space>nf` - Find file in tree

#### UI
- Lualine statusline
- Smooth scrolling
- Dim inactive windows

## Installation

The configuration will auto-install lazy.nvim on first run in terminal Neovim.

**Automatic installations** (no manual steps needed):
- LSP servers (TypeScript, ESLint) - installed by Mason on first startup
- Prettier formatter - installed by Mason on first startup
- Neovim plugins - installed by lazy.nvim on first startup

**Required external tools** (install via Homebrew or system package manager):
- ripgrep (for fast grep)
- fzf (for fuzzy finding)
- bat (for syntax-highlighted previews in fzf)
- git (for git integration)
- Node.js (required for TypeScript/JavaScript LSP servers to run)

## Usage

### In Terminal Neovim
Full configuration with all plugins loads automatically.

### In VSCode/Cursor
Minimal configuration loads (core options + keymaps + text editing plugins).
VSCode/Cursor's built-in features are used for git, file finding, LSP, etc.

## Colorscheme

Using **gruvbox** colorscheme (medium contrast, dark mode) - a warm retro theme matching the darktooth variant from dotfilesold.


