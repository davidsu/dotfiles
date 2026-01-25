# fa - File finder with preview
# Usage: fa
function fa() {
    local filename

    filename=$(find . -type f 2>/dev/null | \
        fzf --exact \
            --preview '$HOME/.dotfiles/bin/preview.sh {}' \
            --preview-window 'top:50%' \
            --header 'Enter: open in nvim | CTRL-s: toggle sort | CTRL-/: toggle preview' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-/:toggle-preview')

    if [[ -f "$filename" ]]; then
        nvim "$filename"
    fi
}
