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
        --bind 'ctrl-s:toggle-sort' \
        --bind 'ctrl-o:execute:open {-1}' \
        --preview 'echo {..-2}; echo $(tput setaf 12){-1} | sed -E '\''s#([&?])#'$(tput setaf 8)'\1'$(tput setaf 10)'#g'\' \
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

function parse_chromium_bookmarks() {
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
