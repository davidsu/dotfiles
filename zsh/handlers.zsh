#!/bin/zsh

# ZSH Command Not Found Handler
# Documentation: man zsh (search for "command_not_found_handler")
# This handler is called by ZSH when a command is not found (exit code 127)
# Allows customization of the "command not found" behavior
#
# See also: man zshmisc for hook documentation
# The handler should return 0 if it handles the error, or 127 if it doesn't

_command_not_found_handler() {
  local cmd="$1"

  # If the argument is a file and NOT executable, open it in Neovim
  # This allows typing a filename directly to edit it
  if [[ -f "$cmd" && ! -x "$cmd" ]]; then
    nvim "$cmd"
    return $?
  fi

  # Not a file or is executable: show standard "command not found" error
  echo "zsh: command not found: $cmd" >&2
  return 127
}
