#!/bin/zsh

# ZSH Preexec Hook: Open Files in Neovim
# Documentation: man zshmisc (search for "add-zsh-hook")
# This hook is called BEFORE any command is executed
# Allows typing a filename directly to edit it (even with paths like config.home.symlink/ghostty/config)

autoload -Uz add-zsh-hook

_preexec_open_in_nvim() {
  local cmd="$(echo -e "$1" | tr -d '[:space:]')"

  # If command exists in PATH, let it execute normally (skip file checks)
  if command -v "$cmd" > /dev/null 2>&1; then
    return 1
  fi

  # Command doesn't exist in PATH - check if it's a local file
  if [[ -f "$cmd" && ! -x "$cmd" ]]; then
    nvim "$cmd"
    return 0
  fi

  # Not a file or is executable: allow normal command execution
  return 1
}

add-zsh-hook preexec _preexec_open_in_nvim
