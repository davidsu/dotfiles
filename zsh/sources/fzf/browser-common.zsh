# Common utilities for browser integration with fzf

function require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd is not installed" >&2
        return 1
    fi
}

function open_urls_with_browser() {
    xargs open
}

function fzf_browser_history() {
    fzf --ansi \
        --multi \
        --delimiter=$'\t' \
        --with-nth '{1}  {2}' \
        --accept-nth 2 \
        --bind 'ctrl-s:toggle-sort' \
        --bind 'ctrl-o:execute:open {2}' \
        --preview 'echo {3}; url-preview.ts {2}' \
        --preview-window 'up:35%:wrap' \
        --bind 'ctrl-/:toggle-preview' \
        "$@"
}

function fzf_browser_bookmarks() {
    fzf --ansi \
        --multi \
        --no-hscroll \
        --tiebreak=begin \
        --delimiter=$'\t' \
        --preview 'echo {2}' \
        --preview-window 'up:3:wrap' \
        --bind 'ctrl-s:toggle-sort' \
        --bind 'ctrl-o:execute:open {2}' \
        "$@"
}

function query_chromium_history() {
    local historyfile="$1"
    local cols="$2"
    local sep='{::}'

    local temp_db="/tmp/browser_history_tmp"
    cp -f "$historyfile" "$temp_db"

    sqlite3 -separator "$sep" "$temp_db" \
        "SELECT substr(title, 1, $cols), url, title
         FROM urls
         ORDER BY last_visit_time DESC"

    rm -f "$temp_db"
}

function format_history_entry() {
    local cols="$1"
    local sep='{::}'
    awk -F "$sep" '{printf "%-'$cols's\t\x1b[36m%s\x1b[m\t%s\n", $1, $2, $3}'
}

function parse_chromium_bookmarks() {
    local bookmarks_file="$1"
    local cols="$2"

    # Recursively extract bookmarks from Chrome's native JSON format
    jq -r '
        def flatten(path):
            if .type == "folder" then
                .children[]? | flatten(path + "/" + .name)
            elif .url then
                (path + "/" + .name) + "\t\u001b[36m" + .url + "\u001b[0m"
            else
                empty
            end;
        .roots | to_entries[] | .value | flatten("")
    ' "$bookmarks_file"
}
