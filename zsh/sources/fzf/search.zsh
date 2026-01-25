# fag - Search files using ripgrep and fzf, open results in nvim
# Usage: fag <search-term>
function fag() {
    local fzfretval filename linenum

    fzfretval=$(rg --line-number --column --color=always --smart-case "$@" | \
        fzf --multi \
            --ansi \
            --delimiter ':' \
            --preview '$HOME/.dotfiles/bin/preview.sh {}' \
            --preview-window 'top:50%:+{2}-/2' \
            --bind 'ctrl-a:select-all' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-/:toggle-preview' \
            --header 'CTRL-a: select-all | CTRL-s: toggle sort | CTRL-/: toggle preview')

    if [[ -n "$fzfretval" ]]; then
        # Extract filename:linenum from first result (format: file:line:col:content)
        IFS=: read -r filename linenum _ <<< "$fzfretval"

        if [[ -f "$filename" ]]; then
            nvim "+${linenum}" "$filename"
        fi
    fi
}
alias frg='fag'
alias '\r'='frg'
