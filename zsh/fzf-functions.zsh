# FZF-powered Shell Functions
# Modern implementations of fzf helper functions from dotfilesold

# fag - Search files using ripgrep and fzf, open results in nvim
# Usage: fag <search-term>
function fag() {
    local fzfretval filename linenum

    # Use ripgrep to search, pipe to fzf with preview
    # Preview command extracts filename and line number, then uses bat to show with highlight
    fzfretval=$(rg --column --line-number --no-heading --color=always --smart-case "$@" | \
        fzf --ansi \
            --multi \
            --delimiter ':' \
            --preview 'bash -c "
                # Extract filename and line number from the selected line
                file=\$(echo {} | cut -d: -f1)
                line=\$(echo {} | cut -d: -f2)
                # Show file with bat, highlighting the matched line with improved styling
                bat --style=numbers,grid --color=always \
                    --highlight-line \$line \
                    --terminal-width \$FZF_PREVIEW_COLUMNS \
                    \$file
            "' \
            --preview-window 'top:50%:wrap:+{2}-/2' \
            --bind 'ctrl-/:toggle-preview' \
            --bind 'ctrl-a:select-all' \
            --bind 'ctrl-s:toggle-sort' \
            --header 'CTRL-a: select-all | CTRL-s: toggle sort | CTRL-/: toggle preview')

    # Parse filename and line number from fzf output
    if [[ -n "$fzfretval" ]]; then
        # Extract first result (filename:linenum:content)
        IFS=: read -r filename linenum _ <<< "$fzfretval"

        if [[ -f "$filename" ]]; then
            # Open in nvim at the specific line
            nvim "+${linenum}" "$filename"
        fi
    fi
}

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

# mru - Most Recently Used files with fzf
# Usage: mru or 1m
export MRU_FILE="$HOME/.local/share/nvim_mru.txt"

function mru() {
    if [[ ! -f "$MRU_FILE" ]]; then
        echo "No MRU history found"
        return 1
    fi

    local fzfresult
    # Filter out fugitive:// URIs and other non-file entries
    fzfresult=$(grep -v '^fugitive://' "$MRU_FILE" | \
        fzf --no-sort \
            --exact \
            --delimiter ':' \
            --preview 'bash -c "
                file=\$(echo {} | cut -d: -f1)
                line=\$(echo {} | cut -d: -f2)
                # Use bat with improved styling for better line highlight visibility
                bat --style=numbers,grid --color=always \
                    --highlight-line \$line \
                    --terminal-width \$FZF_PREVIEW_COLUMNS \
                    \$file
            "' \
            --preview-window 'top:50%:wrap:+{2}-/2' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-/:toggle-preview' \
            --header 'CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --prompt 'MRU> ')

    if [[ -n "$fzfresult" ]]; then
        local filepath linenum column
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

# chromehistory - Browse Chrome history with fzf
# Usage: chromehistory
function chromehistory() {
    local cols sep historyfile
    cols=$(( COLUMNS / 3 ))
    sep='{::}'

    # Find Chrome history file
    if [[ -f ~/Library/Application\ Support/Google/Chrome/Default/History ]]; then
        historyfile=~/Library/Application\ Support/Google/Chrome/Default/History
    elif [[ -f ~/Library/Application\ Support/Google/Chrome/Profile\ 1/History ]]; then
        historyfile=~/Library/Application\ Support/Google/Chrome/Profile\ 1/History
    else
        echo 'Cannot find Chrome history file'
        return 1
    fi

    # Check if sqlite3 is available
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "sqlite3 is not installed"
        return 1
    fi

    # Copy history file (Chrome locks the original)
    cp -f "$historyfile" /tmp/chrome_history_tmp

    # Query history and pipe to fzf
    sqlite3 -separator "$sep" /tmp/chrome_history_tmp \
        "SELECT substr(title, 1, $cols), url
         FROM urls
         ORDER BY last_visit_time DESC" | \
        awk -F "$sep" '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' | \
        fzf --ansi \
            --multi \
            --preview 'echo {..-2}; echo $(tput setaf 12){-1} | sed -E '\''s#([&?])#'$(tput setaf 8)'\1'$(tput setaf 10)'#g'\' \
            --preview-window 'up:35%:wrap' \
            --header 'CTRL-o: open in browser | CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --prompt 'Chrome History> ' \
            --bind 'ctrl-/:toggle-preview' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-o:execute:open {-1}' | \
        perl -pe 's|.*?(https*://.*?)$|\1|' | \
        xargs open

    # Cleanup
    rm -f /tmp/chrome_history_tmp
}

# chromebookmarks - Browse Chrome bookmarks with fzf
# Usage: chromebookmarks
function chromebookmarks() {
    local bookmarks_file cols

    # Find Chrome bookmarks file
    if [[ -f ~/Library/Application\ Support/Google/Chrome/Profile\ 1/Bookmarks ]]; then
        bookmarks_file=~/Library/Application\ Support/Google/Chrome/Profile\ 1/Bookmarks
    elif [[ -f ~/Library/Application\ Support/Google/Chrome/Default/Bookmarks ]]; then
        bookmarks_file=~/Library/Application\ Support/Google/Chrome/Default/Bookmarks
    else
        echo 'Cannot find Chrome bookmarks file'
        return 1
    fi

    # Check if ruby is available
    if ! command -v ruby >/dev/null 2>&1; then
        echo "ruby is not installed"
        return 1
    fi

    cols=$(( COLUMNS / 2 ))

    # Parse bookmarks JSON with Ruby and display with fzf
    ruby -rjson -e "
        file = File.expand_path('$bookmarks_file')
        json = JSON.parse(File.read(file))

        def build(parent, node)
            name = [parent, node['name']].compact.join('/')
            if node['type'] == 'folder'
                node['children']&.map { |child| build(name, child) } || []
            else
                { name: name, url: node['url'] }
            end
        end

        def trim(str, width)
            len = 0
            str.each_char.with_index do |char, idx|
                len += char =~ /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/ ? 2 : 1
                return str[0, idx] if len > width
            end
            str
        end

        items = json['roots']
                .values_at('bookmark_bar', 'synced', 'other')
                .compact
                .flat_map { |e| build(nil, e) }
                .flatten
                .compact

        items.each do |item|
            name = trim(item[:name], $cols)
            puts \"#{name.ljust($cols)}\t\e[36m#{item[:url]}\e[0m\"
        end
    " | fzf --ansi \
          --multi \
          --no-hscroll \
          --tiebreak=begin \
          --delimiter=$'\t' \
          --preview 'echo {2}' \
          --preview-window 'up:3:wrap' \
          --header 'CTRL-o: open in browser | CTRL-s: toggle sort' \
          --bind 'ctrl-s:toggle-sort' \
          --bind 'ctrl-o:execute:open {2}' | \
        awk -F'\t' '{print $2}' | \
        xargs open
}

# Aliases for chromebookmarks
alias cb='chromebookmarks'
alias bookmarks='chromebookmarks'

# fa - File finder with preview
# Usage: fa
function fa() {
    local filename

    filename=$(find . -type f 2>/dev/null | \
        fzf --exact \
            --preview 'bat --style=numbers --color=always {}' \
            --preview-window 'top:50%' \
            --header 'Enter: open in nvim | CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-/:toggle-preview')

    if [[ -f "$filename" ]]; then
        nvim "$filename"
    fi
}
