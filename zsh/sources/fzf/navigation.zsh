# jfzf - Jump to frequently used directories using zoxide + fzf
# Usage: jfzf
# Alias: zi (zoxide interactive)
function jfzf() {
    # Check if zoxide is installed
    if ! command -v zoxide >/dev/null 2>&1; then
        echo "zoxide is not installed. Install with: brew install zoxide"
        return 1
    fi

    local dir
    # Use zoxide to get directory list with scores, pipe to fzf
    # Format: "score /path/to/dir"
    # Note: zoxide outputs lowest scores first, so we don't reverse
    dir=$(zoxide query -l --score | \
        fzf --no-sort \
            --bind 'ctrl-s:toggle-sort' \
            --header 'CTRL-s: toggle sort')

    # Change to selected directory (extract path from "score /path" format)
    if [[ -n "$dir" ]]; then
        # Remove leading whitespace and score, keep only the path
        dir=$(echo "$dir" | awk '{print $2}')
        if [[ -d "$dir" ]]; then
            cd "$dir"
        fi
    fi
}

# Alias for zoxide interactive (standard command)
alias zi='jfzf'
