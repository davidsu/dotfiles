# Brave browser integration with fzf

function find_brave_profile_file() {
    local filename="$1"
    local base_path="$HOME/Library/Application Support/BraveSoftware/Brave-Browser"
    local default_path="$base_path/Default/$filename"
    local profile1_path="$base_path/Profile 1/$filename"

    if [[ -f "$default_path" ]]; then
        echo "$default_path"
    elif [[ -f "$profile1_path" ]]; then
        echo "$profile1_path"
    else
        echo "Cannot find Brave $filename file" >&2
        return 1
    fi
}

function bravehistory() {
    require_command sqlite3 || return 1

    local historyfile
    historyfile=$(find_brave_profile_file "History") || return 1

    local cols=$(( COLUMNS / 3 ))

    query_chromium_history "$historyfile" "$cols" | \
        format_history_entry "$cols" | \
        fzf_browser_history \
            --header 'CTRL-o: open in browser | CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --prompt 'Brave History> ' | \
        extract_url_from_line | \
        open_urls_with_browser
}

function bravebookmarks() {
    require_command jq || return 1

    local bookmarks_file
    bookmarks_file=$(find_brave_profile_file "Bookmarks") || return 1

    local cols=$(( COLUMNS / 2 ))

    parse_chromium_bookmarks "$bookmarks_file" "$cols" | \
        fzf_browser_bookmarks \
            --header 'CTRL-o: open in browser | CTRL-s: toggle sort' | \
        awk -F'\t' '{print $2}' | \
        open_urls_with_browser
}

# Aliases
alias cb='bravebookmarks'
alias bookmarks='bravebookmarks'
