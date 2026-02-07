#!/bin/zsh

# Set up Homebrew PATH for Apple Silicon
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Basic PATH and Environment
export DOTFILES="$HOME/.dotfiles"
export PATH="$DOTFILES/bin:$PATH"

# Set locale to UTF-8 to ensure proper character handling in terminal and tools
export LC_ALL=en_US.UTF-8

# BSD ls color palette (macOS)
export LSCOLORS=GxFxCxDxBxegedabagaced

# Bat (syntax highlighting) - use gruvbox theme to match Neovim
export BAT_THEME="gruvbox-dark"

# Use Neovim for man pages
export MANPAGER='nvim +Man!'

# Neovim MCP socket path for Claude Code integration
# The mcp-neovim-server reads NVIM_SOCKET_PATH to find the Neovim RPC socket.
# Normally this would be hardcoded in .mcp.json, but we need multiple connections:
# each Neovim instance embedding Claude Code (via claudecode.nvim) starts its own
# socket at /tmp/nvim{pid} and passes NVIM_SOCKET_PATH as a process env var,
# overriding this default. This fallback serves terminal Claude sessions that
# connect to the single socket started by :ClaudeConnect.
export NVIM_SOCKET_PATH="/tmp/nvim"

# FZF Configuration
# Consistent layout: prompt on top, results top-to-bottom, preview on top
export FZF_DEFAULT_OPTS="
  --height=100%
  --layout=reverse
  --preview-window=up:50%:wrap
  --bind=ctrl-/:toggle-preview
  --bind=ctrl-s:toggle-sort
"

# FZF Ctrl+T (file search) - preview with bat (directories use tree)
export FZF_CTRL_T_OPTS="
  --preview '[[ -d {} ]] && tree -C -L 2 {} | head -200 || bat --style=numbers --color=always --line-range :500 {}'
"

# FZF Ctrl+R (history search) - no preview needed
export FZF_CTRL_R_OPTS="
  --preview-window=hidden
"

# FZF Alt+C (directory search) - preview with tree
export FZF_ALT_C_OPTS="
  --preview 'tree -C -L 2 {} | head -200'
"

