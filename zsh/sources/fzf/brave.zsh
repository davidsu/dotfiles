# Brave browser integration with fzf

function find_brave_profile_file() {
    local filename="$1"
    local default_path="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/$filename"
    local profile1_path="$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Profile 1/$filename"

    if [[ -f "$default_path" ]]; then
        echo "$default_path"
    elif [[ -f "$profile1_path" ]]; then
        echo "$profile1_path"
    else
        echo "Cannot find Brave $filename file" >&2
        return 1
    fi
}

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

function fzf_common_browser_bindings() {
    fzf --ansi \
        --multi \
        --bind 'ctrl-s:toggle-sort' \
        --bind 'ctrl-o:execute:open {-1}' \
        "$@"
}

function query_brave_history() {
    local historyfile="$1"
    local cols="$2"
    local sep='{::}'

    local temp_db="/tmp/brave_history_tmp"
    cp -f "$historyfile" "$temp_db"

    sqlite3 -separator "$sep" "$temp_db" \
        "SELECT substr(title, 1, $cols), url
         FROM urls
         ORDER BY last_visit_time DESC"

    rm -f "$temp_db"
}

function format_history_entry() {
    local cols="$1"
    local sep='{::}'
    awk -F "$sep" '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}'
}

function extract_url_from_line() {
    perl -pe 's|.*?(https*://.*?)$|\1|'
}

function parse_brave_bookmarks() {
    local bookmarks_file="$1"
    local cols="$2"

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
    "
}

# bravehistory - Browse Brave history with fzf
function bravehistory() {
    require_command sqlite3 || return 1

    local historyfile
    historyfile=$(find_brave_profile_file "History") || return 1

    local cols=$(( COLUMNS / 3 ))

    query_brave_history "$historyfile" "$cols" | \
        format_history_entry "$cols" | \
        fzf_common_browser_bindings \
            --preview 'echo {..-2}; echo $(tput setaf 12){-1} | sed -E '\''s#([&?])#'$(tput setaf 8)'\1'$(tput setaf 10)'#g'\' \
            --preview-window 'up:35%:wrap' \
            --header 'CTRL-o: open in browser | CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --prompt 'Brave History> ' \
            --bind 'ctrl-/:toggle-preview' | \
        extract_url_from_line | \
        open_urls_with_browser
}

# bravebookmarks - Browse Brave bookmarks with fzf
function bravebookmarks() {
    require_command ruby || return 1

    local bookmarks_file
    bookmarks_file=$(find_brave_profile_file "Bookmarks") || return 1

    local cols=$(( COLUMNS / 2 ))

    parse_brave_bookmarks "$bookmarks_file" "$cols" | \
        fzf --ansi \
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
        open_urls_with_browser
}

# Aliases
alias cb='bravebookmarks'
alias bookmarks='bravebookmarks'
