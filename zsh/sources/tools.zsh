#!/bin/zsh

# Initialize Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Initialize mise (Node, etc.)
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

# Initialize fzf key bindings and completion
if command -v fzf >/dev/null 2>&1; then
    # Homebrew standard paths for fzf shell integration
    if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
        source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
        source /opt/homebrew/opt/fzf/shell/completion.zsh
    elif [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
        source /usr/local/opt/fzf/shell/key-bindings.zsh
        source /usr/local/opt/fzf/shell/completion.zsh
    fi
fi

