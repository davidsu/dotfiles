#!/bin/zsh

# Initialize Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Initialize fnm (Fast Node Manager)
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi

# fzf shell integration
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh 2>/dev/null
source /opt/homebrew/opt/fzf/shell/completion.zsh 2>/dev/null

