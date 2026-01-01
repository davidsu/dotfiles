# Zoxide - Smarter cd command
# Tracks frequently used directories and provides smart navigation

# Initialize zoxide if installed
if command -v zoxide >/dev/null 2>&1; then
    # Initialize zoxide (replaces 'cd' with 'z' for smart jumping)
    eval "$(zoxide init zsh)"
fi
