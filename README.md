# Dotfiles

A modern, performance-focused dotfiles configuration optimized exclusively for macOS.

## Quick Start

For a brand-new macOS machine, you can bootstrap everything with a single copy/paste command:

```bash
curl -fsSL https://raw.githubusercontent.com/davidsu/dotfiles/master/installation/bootstrap.sh | bash
```

### Post-Installation: iTerm2 Font Configuration

After installation, you need to manually configure iTerm2 to use the installed Nerd Font for proper icon display:

1. Open **iTerm2 Preferences** (Cmd+,)
2. Go to **Profiles → Text**
3. Enable **"Use a different font for non-ASCII text"** checkbox
4. For the **Non-ASCII Font**, select **"JetBrainsMono Nerd Font Mono"** (Regular, 12pt)
5. Restart iTerm2 completely (Cmd+Q, then reopen)

This enables proper display of icons in nvim-tree and other terminal applications that use Nerd Font glyphs.

## Prerequisites

- **macOS with Apple Silicon**: This configuration is designed for macOS on Apple Silicon (M1/M2/M3/M4 chips). Intel Mac support has been removed for simplicity.
- **Homebrew**: The installation script will attempt to install Homebrew if it's missing.

## Manual Installation

Clone this repository into `~/.dotfiles` and run the installation script:

```bash
git clone git@github.com:davidsu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./installation/install.sh
```

The script will:
1. Perform pre-flight system checks.
2. Bootstrap `mise` (a multi-language version manager) for Node.js version management.
3. Install and verify all tools defined in `installation/tools.json`.

## Architecture

- **`installation/`**: Contains the bootstrap and dependency management scripts.
- **`zsh/`**: Modular Zsh configuration files (`env.zsh`, `aliases.zsh`, `completion.zsh`, etc.). Files ending in `.home.zsh` are symlinked to `$HOME` (e.g., `zshrc.home.zsh` -> `~/.zshrc`).
- **`config.home.symlink/`**: Configuration directory symlinked to `~/.config`.
- **`tools.json`**: The single source of truth for all tools and dependencies.
- **`planning.md`**: Detailed technical specification and project goals.
- **`tasks.md`**: Current development progress and roadmap.

## Core Tools

This dotfiles setup includes carefully selected tools for an efficient development workflow:

### Development Environment
- **Neovim**: Primary text editor with Lua-based configuration for fast startup and modern plugin ecosystem
- **mise**: Multi-language version manager for Node.js and other runtimes (successor to rtx)
- **ripgrep**: Fast, line-oriented search tool (replaces ag) with extensive integration throughout the setup

### Shell & Terminal
- **Zsh**: Modern shell with plugin management via Antidote
- **Starship**: Minimal, blazing-fast, and infinitely customizable shell prompt
- **iTerm2**: Feature-rich terminal emulator with profile management and shell integration

### Shell Customizations
This setup includes several core Zsh optimizations and productivity helpers, organized in a modular structure within the `zsh/` directory:

- **Modularity & Maintenance**:
  - **Modular Files**: Config is split into `env.zsh`, `aliases.zsh`, `completion.zsh`, `keybindings.zsh`, `options.zsh`, and `tools.zsh`.
  - **Easy Reloading**: Use the `reload` function or the `a` alias to instantly refresh your entire Zsh configuration.
- **Navigation**:
  - `auto_cd`: Change directory by simply typing its name
  - `jd`: Shortcut for `cd ~/.dotfiles`
  - `jp`: Shortcut for `cd ~/projects`
- **Productivity**:
  - **Global Aliases**: Use `G` (grep), `L` (less), `T` (tail), `H` (head), and `W` (wc -l) anywhere in a command
  - **Fuzzy Search**: `fzf` integration for history and file finding
  - **Smart Completion**: Case-insensitive and verbose tab completion initialized via `compinit`
- **Keybindings**:
  - **History Search**: `Ctrl+P`/`Ctrl+N` and Up/Down arrows for prefix-based history search (via `up-line-or-beginning-search`)
  - `Ctrl+G`: Push current line to the buffer (clear line to run another command, then restore)
  - `Ctrl+H`: Run help for the current command
- **Safety**: `HIST_VERIFY` prevents immediate execution of history expansions

### Productivity Tools
- **fzf**: Command-line fuzzy finder for efficient file and content searching
  - `fag <pattern>` - Search files with ripgrep and open in nvim
  - `fa` - File finder with bat-powered preview
  - `mru` or `1m` - Most recently used files (shell and nvim)
  - `zi` or `jfzf` - Jump to frequently used directories with zoxide
  - `chromehistory` - Browse Chrome history
  - `chromebookmarks` or `cb` - Browse Chrome bookmarks
- **Karabiner-Elements**: Powerful keyboard customization with Vim-style navigation and smart modifier keys
- **Rectangle**: Window management with keyboard shortcuts for moving and resizing windows
- **macOS Spotlight**: Built-in clipboard history (⌘+Space → ⌘+4) with configurable retention (30 min, 8 hours, or 7 days)

### Container & Version Control
- **Docker (Colima)**: Lightweight container runtime for development environments
- **Git**: Version control with enhanced configuration and productivity shortcuts
- **git-open**: Opens the GitHub/GitLab page for a repository in your browser

## Keyboard Customization (Karabiner-Elements)

This dotfiles includes comprehensive keyboard remappings via Karabiner-Elements:

### Navigation Layer
- **Fn + H/J/K/L** → Arrow keys (Vim-style navigation)
- **Fn + N/M** → Home/End keys

### Volume Controls (FC660C Keyboard)
- **Fn + 9** → Volume Down
- **Fn + 0** → Volume Up

### Smart Modifier Keys
- **Caps Lock**: Tap for Escape, hold for Left Control
- **Return**: Tap for Return, hold for Right Control

### Function Key Remapping
- **F1/F2** → Display brightness controls
- **F3/F4** → Mission Control/Launchpad
- **F5/F6** → Keyboard illumination
- **F7/F8/F9** → Media controls (rewind/play/fast-forward)
- **F10/F11/F12** → Volume controls

### Device-Specific Configuration
- Optimized for FC660C mechanical keyboard
- Custom Fn function key mappings

## Logs

Installation logs are captured in `~/Library/Logs/dotfiles/install.log`.
Error logs are captured in `~/Library/Logs/dotfiles/install_errors.log`.

