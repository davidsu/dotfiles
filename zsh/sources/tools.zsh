#!/bin/zsh

# Initialize Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Initialize mise (Node, etc.)
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

# fzf shell integration
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh 2>/dev/null
source /opt/homebrew/opt/fzf/shell/completion.zsh 2>/dev/null

