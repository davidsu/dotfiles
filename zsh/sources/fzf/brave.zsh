# bravehistory - Browse Brave history with fzf
# Usage: bravehistory
function bravehistory() {
    local cols sep historyfile
    cols=$(( COLUMNS / 3 ))
    sep='{::}'

    # Find Brave history file
    if [[ -f ~/Library/Application\ Support/BraveSoftware/Brave-Browser/Default/History ]]; then
        historyfile=~/Library/Application\ Support/BraveSoftware/Brave-Browser/Default/History
    elif [[ -f ~/Library/Application\ Support/BraveSoftware/Brave-Browser/Profile\ 1/History ]]; then
        historyfile=~/Library/Application\ Support/BraveSoftware/Brave-Browser/Profile\ 1/History
    else
        echo 'Cannot find Brave history file'
        return 1
    fi

    # Check if sqlite3 is available
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "sqlite3 is not installed"
        return 1
    fi

    # Copy history file (Brave locks the original)
    cp -f "$historyfile" /tmp/brave_history_tmp

    # Query history and pipe to fzf
    sqlite3 -separator "$sep" /tmp/brave_history_tmp \
        "SELECT substr(title, 1, $cols), url
         FROM urls
         ORDER BY last_visit_time DESC" | \
        awk -F "$sep" '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' | \
        fzf --ansi \
            --multi \
            --preview 'echo {..-2}; echo $(tput setaf 12){-1} | sed -E '\''s#([&?])#'$(tput setaf 8)'\1'$(tput setaf 10)'#g'\' \
            --preview-window 'up:35%:wrap' \
            --header 'CTRL-o: open in browser | CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --prompt 'Brave History> ' \
            --bind 'ctrl-/:toggle-preview' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-o:execute:open {-1}' | \
        perl -pe 's|.*?(https*://.*?)$|\1|' | \
        xargs open

    # Cleanup
    rm -f /tmp/brave_history_tmp
}

# bravebookmarks - Browse Brave bookmarks with fzf
# Usage: bravebookmarks
function bravebookmarks() {
    local bookmarks_file cols

    # Find Brave bookmarks file
    if [[ -f ~/Library/Application\ Support/BraveSoftware/Brave-Browser/Default/Bookmarks ]]; then
        bookmarks_file=~/Library/Application\ Support/BraveSoftware/Brave-Browser/Default/Bookmarks
    elif [[ -f ~/Library/Application\ Support/BraveSoftware/Brave-Browser/Profile\ 1/Bookmarks ]]; then
        bookmarks_file=~/Library/Application\ Support/BraveSoftware/Brave-Browser/Profile\ 1/Bookmarks
    else
        echo 'Cannot find Brave bookmarks file'
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

# Aliases for bravebookmarks
alias cb='bravebookmarks'
alias bookmarks='bravebookmarks'
