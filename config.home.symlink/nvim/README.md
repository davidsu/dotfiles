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
│   ├── plugins/               # Plugin specifications
│   │   ├── init.lua           # Plugin loader
│   │   ├── editing.lua        # Text editing (surround, commentary, repeat)
│   │   ├── git.lua            # Git integration (fugitive, gitsigns)
│   │   ├── fzf.lua            # Fuzzy finder
│   │   ├── tree.lua           # File explorer (nvim-tree)
│   │   ├── statusline.lua     # Lualine statusline
│   │   └── ui.lua             # UI enhancements
│   └── utils/                 # Custom utility functions
│       └── window.lua         # Smart window navigation
└── MIGRATION_PLAN.md          # Full migration plan and architecture
```

## Features

### Environment Detection
- Automatically detects VSCode/Cursor vs Terminal Neovim
- Loads minimal config in VSCode/Cursor (just keymaps and text editing)
- Loads full plugin suite in terminal

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

### Terminal-Only Features

#### Text Editing
- vim-surround - Change/delete surroundings
- vim-commentary - Comment toggling
- vim-repeat - Repeat plugin actions

#### Git Integration
- vim-fugitive - Git wrapper
- vim-rhubarb - GitHub integration
- gitsigns.nvim - Git signs in gutter
  - `]g`/`[g` - Next/prev hunk
  - `<space>hs` - Stage hunk
  - `<space>hr` - Reset hunk
  - `<space>gs` - Git status
  - `<space>gd` - Git diff

#### Fuzzy Finder (FZF)
- `<c-t>` - Find git files
- `<space>fa` - Find all files
- `<space>fw` - Grep word (ripgrep)
- `<space>fb` / `\b` / `1b` - Find buffers
- `<space>fh` - Command history

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
- git (for git integration)

## Usage

### In Terminal Neovim
Full configuration with all plugins loads automatically.

### In VSCode/Cursor
Minimal configuration loads (core options + keymaps + text editing plugins).
VSCode/Cursor's built-in features are used for git, file finding, LSP, etc.

## Next Steps

See `MIGRATION_PLAN.md` for:
- Treesitter setup
- LSP configuration
- Completion setup
- Colorscheme
- Advanced features


