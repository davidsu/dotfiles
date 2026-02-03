# Chrome browser integration with fzf
# Note: Chrome with sync enabled stores bookmarks in Google Account, not locally.
# Use `chromeExportBookmarks` to export, then `chromebookmarks` to browse.

CHROME_BOOKMARKS_DIR="$HOME/.bookmarks"
CHROME_BOOKMARKS_JSON="$CHROME_BOOKMARKS_DIR/chrome.json"
CHROME_BOOKMARKS_HTML="$CHROME_BOOKMARKS_DIR/chrome.html"

# chromeExportBookmarks - Export ALL Chrome bookmarks (including synced folders) to JSON
function chromeExportBookmarks() {
    mkdir -p "$CHROME_BOOKMARKS_DIR"

    local output_file="$CHROME_BOOKMARKS_DIR/chrome.json"

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
        echo "$result" > "$output_file"
        local count=$(echo "$result" | grep -o '"url"' | wc -l | tr -d ' ')
        echo "Exported $count bookmarks to $output_file"
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

function query_chrome_history() {
    local historyfile="$1"
    local cols="$2"
    local sep='{::}'

    local temp_db="/tmp/chrome_history_tmp"
    cp -f "$historyfile" "$temp_db"

    sqlite3 -separator "$sep" "$temp_db" \
        "SELECT substr(title, 1, $cols), url
         FROM urls
         ORDER BY last_visit_time DESC"

    rm -f "$temp_db"
}

function parse_chrome_bookmarks_json() {
    local bookmarks_file="$1"
    local cols="$2"

    # Our exported format: [{path: '...', url: '...'}, ...]
    jq -r '.[] | "\(.path)\t\u001b[36m\(.url)\u001b[0m"' "$bookmarks_file"
}

function parse_chrome_bookmarks_html() {
    local html_file="$1"
    local cols="$2"

    ruby -e "
        require 'rexml/document'

        def trim(str, width)
            len = 0
            str.each_char.with_index do |char, idx|
                len += char =~ /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/ ? 2 : 1
                return str[0, idx] if len > width
            end
            str
        end

        def parse_folder(element, path = [])
            items = []
            element.elements.each do |child|
                case child.name.downcase
                when 'dt'
                    # Check for folder (H3) or link (A)
                    h3 = child.elements['H3'] || child.elements['h3']
                    a = child.elements['A'] || child.elements['a']
                    dl = child.elements['DL'] || child.elements['dl']

                    if h3
                        folder_name = h3.text || ''
                        if dl
                            items.concat(parse_folder(dl, path + [folder_name]))
                        end
                    elsif a
                        name = a.text || ''
                        url = a.attributes['HREF'] || a.attributes['href']
                        full_path = (path + [name]).join('/')
                        items << { name: full_path, url: url } if url
                    end
                when 'dl'
                    items.concat(parse_folder(child, path))
                end
            end
            items
        end

        html = File.read('$html_file')
        # Clean up HTML for REXML (it's not valid XML)
        html = html.gsub(/<p>/i, '').gsub(/<\/p>/i, '')
        html = html.gsub(/<HR>/i, '').gsub(/<hr>/i, '')
        html = html.gsub(/&(?!amp;|lt;|gt;|quot;|apos;)/, '&amp;')

        # Wrap in root element if needed
        html = '<root>' + html + '</root>' unless html.strip.start_with?('<root')

        begin
            doc = REXML::Document.new(html)
            dl = doc.elements['//DL'] || doc.elements['//dl']

            if dl
                items = parse_folder(dl)
                items.each do |item|
                    name = trim(item[:name], $cols)
                    puts \"#{name.ljust($cols)}\t\e[36m#{item[:url]}\e[0m\"
                end
            end
        rescue => e
            STDERR.puts \"Error parsing HTML: #{e.message}\"
            exit 1
        end
    "
}

function find_chrome_bookmarks_export() {
    # First check ~/.bookmarks/chrome.json (our exported format with ALL bookmarks)
    if [[ -f "$CHROME_BOOKMARKS_JSON" ]]; then
        echo "$CHROME_BOOKMARKS_JSON"
        return 0
    fi

    # Then check ~/.bookmarks/chrome.html
    if [[ -f "$CHROME_BOOKMARKS_HTML" ]]; then
        echo "$CHROME_BOOKMARKS_HTML"
        return 0
    fi

    # Fall back to recent exports in Downloads
    local downloads="$HOME/Downloads"
    local latest=$(find "$downloads" -maxdepth 1 -name "bookmarks*.html" -mtime -7 2>/dev/null | sort -r | head -1)

    if [[ -n "$latest" ]]; then
        echo "$latest"
        return 0
    fi
    return 1
}

# chromehistory - Browse Chrome history with fzf
function chromehistory() {
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "sqlite3 is not installed" >&2
        return 1
    fi

    local historyfile
    historyfile=$(find_chrome_profile_file "History") || return 1

    local cols=$(( COLUMNS / 3 ))
    local sep='{::}'

    query_chrome_history "$historyfile" "$cols" | \
        awk -F "$sep" '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' | \
        fzf --ansi \
            --multi \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-o:execute:open {-1}' \
            --preview 'echo {..-2}; echo $(tput setaf 12){-1} | sed -E '\''s#([&?])#'$(tput setaf 8)'\1'$(tput setaf 10)'#g'\' \
            --preview-window 'up:35%:wrap' \
            --header 'CTRL-o: open in browser | CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --prompt 'Chrome History> ' \
            --bind 'ctrl-/:toggle-preview' | \
        perl -pe 's|.*?(https*://.*?)$|\1|' | \
        xargs open
}

# chromebookmarks - Browse Chrome bookmarks with fzf
# Usage: chromebookmarks [file.json|file.html]
# If no file provided, looks for ~/.bookmarks/chrome.json first
function chromebookmarks() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "jq is not installed" >&2
        return 1
    fi

    local cols=$(( COLUMNS / 2 ))
    local bookmarks_source=""
    local parse_func=""

    # Check if file was provided as argument
    if [[ -n "$1" && -f "$1" ]]; then
        bookmarks_source="$1"
        [[ "$1" == *.html ]] && parse_func="parse_chrome_bookmarks_html" || parse_func="parse_chrome_bookmarks_json"
    else
        # Try to find export (checks ~/.bookmarks/chrome.json first, then .html, then Downloads)
        local export_file
        export_file=$(find_chrome_bookmarks_export)
        if [[ -n "$export_file" ]]; then
            bookmarks_source="$export_file"
            [[ "$export_file" == *.html ]] && parse_func="parse_chrome_bookmarks_html" || parse_func="parse_chrome_bookmarks_json"
            echo "Using: $export_file" >&2
        else
            echo "No bookmarks found. Run 'chromeExportBookmarks' first." >&2
            return 1
        fi
    fi

    $parse_func "$bookmarks_source" "$cols" | \
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
        xargs open
}
