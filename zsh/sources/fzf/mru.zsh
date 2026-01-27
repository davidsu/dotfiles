# mru - Most Recently Used files with fzf
# Usage: mru or 1m
export MRU_FILE="$HOME/.local/share/nvim_mru.txt"

function mru() {
    if [[ ! -f "$MRU_FILE" ]]; then
        echo "No MRU history found"
        return 1
    fi

    local fzfresult filepath linenum column

    # Filter out fugitive:// URIs and other non-file entries
    fzfresult=$(grep -v '^fugitive://' "$MRU_FILE" | \
        fzf --no-sort \
            --delimiter ':' \
            --preview '$HOME/.dotfiles/bin/preview.ts {}' \
            --preview-window 'top:50%:+{2}-/2' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-/:toggle-preview' \
            --header 'CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --prompt 'MRU> ')

    if [[ -n "$fzfresult" ]]; then
        IFS=: read -r filepath linenum column <<< "$fzfresult"

        if [[ -f "$filepath" ]]; then
            # Change to git root if in a git repo
            local filedir=$(dirname "$filepath")
            cd "$filedir"
            if git rev-parse --show-toplevel > /dev/null 2>&1; then
                cd $(git rev-parse --show-toplevel)
            fi

            # Open file at saved position
            nvim "+call cursor($linenum, $column)" "$filepath"
        fi
    fi
}

alias 1m='mru'

# mru-clean - Remove invalid/deleted file entries from MRU
# Usage: mru-clean
function mru-clean() {
    if [[ ! -f "$MRU_FILE" ]]; then
        echo "No MRU history found at $MRU_FILE"
        return 1
    fi

    local temp_file=$(mktemp)
    local removed_count=0
    local kept_count=0

    echo "Cleaning MRU file: $MRU_FILE"

    # Read each entry and check if file exists
    while IFS=: read -r filepath line col; do
        if [[ -f "$filepath" ]]; then
            echo "$filepath:$line:$col" >> "$temp_file"
            ((kept_count++))
        else
            echo "  Removing: $filepath (file not found)"
            ((removed_count++))
        fi
    done < "$MRU_FILE"

    # Replace original file with cleaned version
    mv "$temp_file" "$MRU_FILE"

    echo ""
    echo "MRU cleanup complete:"
    echo "  Kept: $kept_count entries"
    echo "  Removed: $removed_count entries"
}

alias removeMruInvalidEntries='mru-clean'
