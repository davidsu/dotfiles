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

