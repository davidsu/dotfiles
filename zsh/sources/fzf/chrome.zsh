# Chrome browser integration with fzf
# Note: Chrome with sync stores bookmarks in Google Account, not locally.
# Use `chromeExportBookmarks` to export, then `chromebookmarks` to browse.

CHROME_BOOKMARKS_DIR="$HOME/.bookmarks"
CHROME_BOOKMARKS_FILE="$CHROME_BOOKMARKS_DIR/chrome.json"

# chromeExportBookmarks - Export ALL Chrome bookmarks (including synced folders) to JSON
function chromeExportBookmarks() {
    mkdir -p "$CHROME_BOOKMARKS_DIR"

    # Use osascript with two-step JS execution (async results need window variable)
    local result
    result=$(osascript -e '
tell application "Google Chrome"
    activate
    open location "chrome://bookmarks"
    delay 2
    set jsCode to "chrome.bookmarks.getTree().then(tree => { function flatten(nodes, path) { let results = []; for (const node of nodes) { const currentPath = path ? path + \"/\" + node.title : node.title; if (node.url) { results.push({ path: currentPath, url: node.url }); } if (node.children) { results = results.concat(flatten(node.children, currentPath)); } } return results; } window._exportedBookmarks = JSON.stringify(flatten(tree)); })"
    execute front window'\''s active tab javascript jsCode
    delay 1
    set jsResult to execute front window'\''s active tab javascript "window._exportedBookmarks"
    return jsResult
end tell
')

    if [[ -n "$result" && "$result" != "null" && "$result" != "missing value" ]]; then
        echo "$result" > "$CHROME_BOOKMARKS_FILE"
        local count=$(echo "$result" | grep -o '"url"' | wc -l | tr -d ' ')
        echo "Exported $count bookmarks to $CHROME_BOOKMARKS_FILE"
    else
        echo "Failed to extract bookmarks. Make sure Chrome is running." >&2
        return 1
    fi
}

function find_chrome_profile_file() {
    local filename="$1"
    local base_path="$HOME/Library/Application Support/Google/Chrome"
    local default_path="$base_path/Default/$filename"
    local profile1_path="$base_path/Profile 1/$filename"

    if [[ -f "$default_path" ]]; then
        echo "$default_path"
    elif [[ -f "$profile1_path" ]]; then
        echo "$profile1_path"
    else
        echo "Cannot find Chrome $filename file" >&2
        return 1
    fi
}

function chromehistory() {
    require_command sqlite3 || return 1

    local historyfile
    historyfile=$(find_chrome_profile_file "History") || return 1

    local cols=$(( COLUMNS / 3 ))

    query_chromium_history "$historyfile" "$cols" | \
        format_history_entry "$cols" | \
        fzf_browser_history \
            --header 'CTRL-o: open in browser | CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --prompt 'Chrome History> ' | \
        extract_url_from_line | \
        open_urls_with_browser
}

# chromebookmarks - Browse Chrome bookmarks with fzf
# Uses exported JSON from chromeExportBookmarks (for synced bookmarks)
function chromebookmarks() {
    require_command jq || return 1

    local cols=$(( COLUMNS / 2 ))

    if [[ ! -f "$CHROME_BOOKMARKS_FILE" ]]; then
        echo "No bookmarks found. Run 'chromeExportBookmarks' first." >&2
        return 1
    fi

    # Parse exported JSON: [{path: '...', url: '...'}, ...]
    jq -r '.[] | "\(.path)\t\u001b[36m\(.url)\u001b[0m"' "$CHROME_BOOKMARKS_FILE" | \
        fzf_browser_bookmarks \
            --header 'CTRL-o: open in browser | CTRL-s: toggle sort' | \
        awk -F'\t' '{print $2}' | \
        open_urls_with_browser
}
