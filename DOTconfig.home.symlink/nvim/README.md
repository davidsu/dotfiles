# ⚡ Neovim Configuration

Modern Neovim configuration with environment detection and modular plugin system.

> 🎯 **Goal**: Clean, fast, and productive editing experience for TypeScript/JavaScript development

## 📁 Structure

```
nvim/
├── init.lua                    # Main entry point
├── lua/
│   ├── core/                   # Core functionality
│   │   ├── options.lua        # Core Vim options (all environments)
│   │   ├── keymaps.lua        # Universal keymaps (including VSCode-compatible mappings)
│   │   ├── autocmds.lua       # Autocommands
│   │   ├── commands.lua       # User-defined commands
│   │   └── lazy.lua           # Plugin manager bootstrap
│   ├── config/                # Feature modules
│   │   ├── claude.lua         # Claude AI integration settings
│   │   └── mru.lua            # MRU (Most Recently Used) file tracking
│   ├── plugins/               # Plugin specifications
│   │   ├── bufonly.lua        # Delete all buffers except current
│   │   ├── colorizer.lua      # Color highlighting for hex/RGB codes
│   │   ├── colorscheme.lua    # Gruvbox colorscheme
│   │   ├── completion.lua     # Autocompletion (nvim-cmp)
│   │   ├── editing.lua        # Text editing (surround, commentary, repeat)
│   │   ├── folding.lua        # Code folding (nvim-ufo)
│   │   ├── formatting.lua     # Code formatting (conform.nvim with Prettier)
│   │   ├── fzf-lua.lua        # Fuzzy finder (fzf-lua for MRU and LSP)
│   │   ├── git.lua            # Git integration (fugitive, gitsigns)
│   │   ├── interestingwords.lua  # Multi-word highlighting
│   │   ├── lsp.lua            # LSP configuration (TypeScript, ESLint)
│   │   ├── markdown.lua       # Markdown preview (browser-based)
│   │   ├── mason.lua          # LSP server/formatter auto-installer
│   │   ├── mru.lua            # MRU plugin spec
│   │   ├── statusline.lua     # Lualine statusline
│   │   ├── tree.lua           # File explorer (nvim-tree)
│   │   ├── treesitter.lua     # Syntax highlighting (TreeSitter)
│   │   ├── ui.lua             # UI enhancements
│   │   └── unimpaired.lua     # Bracket mappings and toggles
│   └── utils/                 # Custom utility functions
│       ├── buffers.lua        # Buffer management helpers
│       ├── diagnostics.lua    # Diagnostic display in command line
│       ├── floating_window.lua  # Floating window utilities
│       ├── k_cycle.lua        # K key cycling (fold/diagnostic/hover)
│       ├── lsp.lua            # LSP utility functions
│       ├── position.lua       # Cursor position helpers
│       ├── terminal.lua       # Terminal utilities
│       └── window.lua         # Smart window navigation
```

## ✨ Features

### 🔍 Environment & Usage
- Core options, keymaps, and text-editing behavior are defined in Lua
- Plugin setup is handled via `lazy.nvim` and is primarily intended for terminal Neovim

### ⚙️ Core Options (All Environments)
- 📋 System clipboard integration
- ↹ Smart indentation (2 spaces)
- 🔎 Case-insensitive smart search
- ♻️ Persistent undo
- 🚫 No swap/backup files
- ⚡ Ripgrep integration

### 🔄 Core Autocommands
- 💾 **Auto-save**: Files automatically save when focus is lost or switching windows
- ✨ **Yank highlighting**: Brief visual feedback when text is yanked
- 🔃 **Auto-reload**: Buffers automatically reload if file changed externally
- 📝 **Command history sync**: Syncs command-line history across Neovim instances
- 🎯 **TypeScript indentation**: Uses built-in filetype indent instead of TreeSitter

### 🛠️ Core Commands
- `:P` / `:CP` / `:CopyFilePath` - 📄 Copy full file path to clipboard
- `:PP` - 📍 Copy file path with line number to clipboard
- `:CopyFileName` - 📝 Copy file name to clipboard
- `:CopyFileNameNoExtension` - ✂️ Copy file name without extension
- `:CopyRelativeFilePath` - 📁 Copy relative file path to clipboard
- `:Signs` - 👁️ Toggle sign column, gitsigns, and diagnostics

### ⌨️ Universal Keymaps (All Environments)
- `<space><space>` - 💾 Save file
- `j`/`k` - 📜 Move by display lines

**🪟 Window Navigation:**
- `<C-h/j/k/l>` - Move between existing windows
- `gh`/`gj`/`gk`/`gl` - Smart navigation (auto-creates splits at edges)
- `<C-p>` - Previous window

**↔️ Window Resizing:**
- `+` / `_` - Increase/decrease window size (auto-detects split orientation)
- `≠` / `–` - Alt+= / Alt+- alternatives
- `<space>v` / `\x` - Toggle horizontal/vertical resize mode

**🔧 Other Keymaps:**
- `\w` - ❌ Close window
- `<space>qq` - 🧹 Close all helper windows
- `\s` - 🔄 Substitute with very magic
- `m,` / `sa` - 🔀 Switch to alternate file (last buffer)
- `'` - 📌 Jump to mark (exact position instead of line start)
- `q` - 👋 Close help/quickfix/fugitive windows (auto-mapped in those buffers)
- `:h` - 📖 Opens help in new tab (abbreviated from `:tab help`)
- `<C-p>` / `<C-n>` - 📜 Navigate command history (filtered, case-insensitive)

### 💻 Terminal-Only Features

#### 🎨 Syntax Highlighting (Treesitter)
**nvim-treesitter** - Advanced syntax highlighting and code understanding
- ✨ Accurate syntax highlighting (better than regex-based)
- 🎯 Smart indentation based on code structure
- 📦 **Auto-install**: TypeScript, JavaScript, Lua, Markdown, JSON, HTML, CSS parsers
- 🔄 **Update**: Run `:TSUpdate` after upgrading nvim-treesitter
- 🔗 **Matchparen**: Highlights matching brackets when cursor is over them

#### 📂 Code Folding (nvim-ufo)
**Smart fold providers**: LSP → TreeSitter → indent (automatically falls back)

**📝 Markdown**: Uses TreeSitter + indent (better for markdown structure)

**⌨️ Keybindings**:
- `zR` / `zM` - 🌐 Open/close all folds
- `zr` / `zm` - 📊 Open/close folds incrementally
- `za` / `zo` / `zc` - 🔄 Toggle/open/close fold at cursor
- `K` - 👀 Peek fold contents (when cursor on folded line)

💡 Starts with everything open (foldlevel=99)

#### ✏️ Text Editing
**Essential editing plugins**:
- 🔄 **vim-surround** - Change/delete surroundings
- 💬 **vim-commentary** - Comment toggling
- ↩️ **vim-repeat** - Repeat plugin actions
- 🎛️ **vim-unimpaired** - Bracket mappings and toggles

**⌨️ Keybindings**:
- `yow` - 🔀 Toggle wrap
- `yon` - 🔢 Toggle line numbers
- `yos` - ✍️ Toggle spell check
- `]q`/`[q` - ⏭️ Next/prev quickfix
- `]b`/`[b` - 📑 Next/prev buffer

#### 🎯 Word Highlighting (interestingwords.nvim)
Highlight multiple words in different colors simultaneously - perfect for tracking variables/functions!

**⌨️ Keybindings**:
- `<leader>hi` - 🌈 Highlight word under cursor (cycles through 6 colors)
- `<leader>hc` - 🧹 Clear all highlights (both interestingwords and native search)

💡 Preserves syntax highlighting colors (e.g., in diff buffers)

#### 🎨 Color Highlighting (nvim-colorizer)
Shows colors inline for hex codes, RGB values, CSS colors

**Supported formats**: `#RGB`, `#RRGGBB`, `#RRGGBBAA`, `rgb()`, `rgba()`, `hsl()`, CSS color names

✅ Works in all file types

#### 🔀 Git Integration
**Plugins**:
- 🛠️ **vim-fugitive** - Git wrapper
- 🐙 **vim-rhubarb** - GitHub integration
- 📊 **gitsigns.nvim** - Git signs in gutter

**⌨️ Keybindings**:
- `]g`/`[g` - ⏭️ Next/prev hunk
- `<space>hs` - ✅ Stage hunk
- `<space>hr` - ↩️ Reset hunk
- `<space>hu` - ⏮️ Undo stage hunk
- `<space>hp` - 👁️ Preview hunk
- `<space>gs` / `gs` - 📋 Git status
- `<space>gd` - 📊 Git diff
- `gb` - 👤 Git blame

#### 🔍 Fuzzy Finder (FZF)
**File Navigation**:
- `<c-t>` - 📁 Find git files
- `<space>fa` - 📂 Find all files
- `1m` - ⏱️ MRU (Most Recently Used) files (fullscreen, preview on top)

**Search**:
- `<space>fw` - 🔎 Grep word (ripgrep)
- `\a` - 🔍 Ripgrep search (fullscreen with syntax-highlighted preview via bat)
- `\r` - ⚡ FZF Ripgrep search (interactive)

**Navigation**:
- `<space>fb` / `\b` / `1b` - 📑 Find buffers
- `<space>fh` / `1:` / `1;` - 📜 Command history
- `1/` - 🔍 Search history
- `\c` - 🛠️ Browse all available Vim commands
- `\<tab>` - ⌨️ Search all keybindings/keyboard shortcuts
- `<space>fu` - 🎯 Find usages (LSP references with preview, powered by fzf-lua)
- `<space>fq` - 📋 Browse quickfix list with preview

#### ⏱️ MRU (Most Recently Used Files)
**Features**:
- 📝 Automatically tracks every file you open with exact cursor position
- 🔍 `1m` in Neovim opens fullscreen fzf-lua with preview
- 📌 Restores cursor to exact line and column where you left off
- 💾 File-based tracking at `~/.local/share/nvim_mru.txt` (max 100 entries)
- 🗂️ Filters out temporary files, git buffers, help, fugitive, etc.
- ⚡ Works in both terminal (via shell function) and Neovim

💡 Replaces dotfilesold's PM2/Node.js server with simple Lua implementation

#### 🚀 LSP (Language Server Protocol)
Native Neovim LSP with **TypeScript** and **ESLint** support

**🧭 Navigation**:
- `<space>cd` / `gd` - 🎯 Go to definition
- `gD` - 📝 Go to type definition
- `gi` - 🔧 Go to implementation
- `gr` - 🔍 Find references (populates quickfix)
- `<space>fu` - 🎯 Find usages (LSP references with FZF preview)
- `K` - 🔄 Smart cycle: Fold peek → Diagnostic → LSP hover (resets on window close)

**⚡ Actions**:
- `<space>rn` - ✏️ Rename symbol
- `<space>ca` / `<space>cf` - 💡 Code actions
- `<space>f` - 🎨 Format document (uses Prettier via conform.nvim)

**🩺 Diagnostics**:
- ✅ Shows both TypeScript errors AND ESLint rule violations
- 💡 Diagnostics appear only in normal mode (not while typing in insert mode)
- `<space>lo` - 📋 Open diagnostics list
- `]d` / `[d` - ⏭️ Next/prev diagnostic
- `<Esc>` / `<C-c>` - ❌ Close floating windows (hover, diagnostics, etc.)

#### 🎨 Formatting
Powered by **conform.nvim** with **Prettier**

**Features**:
- 🔍 Automatically finds and uses project's Prettier config (`.prettierrc`, `prettier.config.js`)
- 📦 Uses project's `node_modules/.bin/prettier` if available, falls back to Mason-installed version
- 💾 **Auto-format on save** for TypeScript, JavaScript, JSON, CSS, HTML, Markdown, YAML
- ⌨️ **Manual format**: `<space>f` or `:Format`
- 🎯 Works even when opening files outside current working directory (auto-detects project root)
- 📂 **Project root detection**: Walks up directory tree to find `package.json`, `.git`, etc.

#### 📦 Mason (LSP Server Management)
**Automatic installation** of LSP servers and formatters on first Neovim startup

**🔧 Auto-installed tools**:
- 🔷 `ts_ls` - TypeScript/JavaScript language server
- ✅ `eslint` - ESLint language server for linting diagnostics
- 🎨 `prettier` - Code formatter

**💡 Features**:
- 🖥️ **UI**: Run `:Mason` to see installed tools, update them, or install additional ones
- ⚡ **Zero manual setup** - works out of the box on new machines
- 📁 **Per-project versions respected**: If project has tools in `node_modules`, those are used instead

#### 💡 Completion (IntelliSense)
Powered by **nvim-cmp** with LSP integration

**✨ Popup opens automatically** as you type

**🧭 Navigation**:
- `<C-n>` / `<C-p>` - ⏭️ Next/previous completion item
- `<C-d>` / `<C-f>` - 📜 Scroll documentation up/down

**✅ Accept completion**:
- `<Tab>` - ⚡ Accept highlighted item (or first item if none selected)
- `<CR>` (Enter) - ✨ Accept only if explicitly selected

**❌ Close popup**:
- `<C-e>` - Close completion menu (stays in insert mode)
- `<Esc>` - Close and exit insert mode

**⚙️ Manual trigger**:
- `<C-Space>` - 🔄 Manually trigger completion

📊 **Sources**: LSP (highest priority), file paths, buffer words

#### 📝 Markdown Preview
Powered by **live-preview.nvim** (pure Lua, no external dependencies)

**Features**:
- ⚡ **Live updates** - Real-time preview as you type
- 🚫 **Zero dependencies** - No Node.js, Python, Deno, or yarn required
- 🔢 **KaTeX math** - Supports LaTeX math equations
- 📊 **Mermaid diagrams** - Renders flowcharts, sequence diagrams, etc.
- 🌐 Opens in your default browser on port 5500
- 🔒 Auto-closes server when Neovim exits

**⌨️ Keybindings** (in markdown files):
- `<leader>mp` - ▶️ Start live preview
- `<leader>ms` - ⏹️ Stop preview

#### 🗂️ File Explorer
- `1n` - 🌳 Toggle file tree
- `<space>nf` - 🔍 Find file in tree

#### 📑 Buffer Management
- `:BufOnly` - 🧹 Delete all buffers except current buffer
- 🎯 Smart buffer deletion with MRU tracking (via custom utils/buffers.lua)

#### 🎭 UI Enhancements
- 📊 **Lualine statusline** - Beautiful, informative status line
- 🌊 **Smooth scrolling** - Buttery smooth navigation
- 🌑 **Dim inactive windows** - Focus on what matters

## 📦 Installation

The configuration will auto-install **lazy.nvim** on first run in terminal Neovim.

### ✅ Automatic installations (no manual steps needed):
- 🔷 **LSP servers** (TypeScript, ESLint) - installed by Mason on first startup
- 🎨 **Prettier formatter** - installed by Mason on first startup
- 🔌 **Neovim plugins** - installed by lazy.nvim on first startup

### 🛠️ Required external tools
Install via Homebrew or system package manager:
- ⚡ **ripgrep** - for fast grep
- 🔍 **fzf** - for fuzzy finding
- 🦇 **bat** - for syntax-highlighted previews in fzf
- 🔀 **git** - for git integration
- 📦 **Node.js** - required for TypeScript/JavaScript LSP servers to run

## 🚀 Usage

### 💻 In Terminal Neovim
Full configuration with all plugins loads automatically.
## 🎨 Colorscheme

Using **gruvbox** colorscheme (medium contrast, dark mode) - a warm retro theme matching the darktooth variant from dotfilesold.

---

<div align="center">

**✨ Happy coding! ✨**

</div>


