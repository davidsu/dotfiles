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
│   │   ├── editing.lua        # Text editing (surround, commentary, repeat)
│   │   ├── git.lua            # Git integration (fugitive, gitsigns)
│   │   ├── fzf.lua            # Fuzzy finder (fzf.vim)
│   │   ├── fzf-lua.lua        # Fuzzy finder (fzf-lua for MRU)
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

#### File Explorer
- `1n` - Toggle file tree
- `<space>nf` - Find file in tree

#### UI
- Lualine statusline
- Smooth scrolling
- Dim inactive windows

## Installation

The configuration will auto-install lazy.nvim on first run in terminal Neovim.

Required external tools:
- ripgrep (for fast grep)
- fzf (for fuzzy finding)
- bat (for syntax-highlighted previews in fzf)
- git (for git integration)

## Usage

### In Terminal Neovim
Full configuration with all plugins loads automatically.

### In VSCode/Cursor
Minimal configuration loads (core options + keymaps + text editing plugins).
VSCode/Cursor's built-in features are used for git, file finding, LSP, etc.

## Colorscheme

Using **gruvbox** colorscheme (medium contrast, dark mode) - a warm retro theme matching the darktooth variant from dotfilesold.

## Next Steps

See `MIGRATION_PLAN.md` for:
- LSP configuration
- Completion setup
- Advanced features


