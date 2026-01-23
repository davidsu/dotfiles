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

# FZF Configuration
# Consistent layout: prompt on top, results top-to-bottom, preview on top
export FZF_DEFAULT_OPTS="
  --height=100%
  --layout=reverse
  --preview-window=up:50%:wrap
  --bind=ctrl-/:toggle-preview
  --bind=ctrl-s:toggle-sort
"

# FZF Ctrl+T (file search) - preview with bat
export FZF_CTRL_T_OPTS="
  --preview 'bat --style=numbers --color=always --line-range :500 {}'
"

# FZF Ctrl+R (history search) - no preview needed
export FZF_CTRL_R_OPTS="
  --preview-window=hidden
"

# FZF Alt+C (directory search) - preview with tree
export FZF_ALT_C_OPTS="
  --preview 'tree -C -L 2 {} | head -200'
"

