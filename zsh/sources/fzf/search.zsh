# fag - Search files using ripgrep and fzf, load the selected matches into nvim's quickfix list
# Usage: fag <search-term>   (CTRL-l selects all matches, then Enter loads them all)
function fag() {
    local matches tmpfile

    matches=$(rg --line-number --column --color=always --smart-case "$@" | \
        fzf --multi \
            --ansi \
            --delimiter ':' \
            --preview '$HOME/.dotfiles/bin/preview.ts {}' \
            --preview-window 'top:50%:+{2}-/2' \
            --bind 'ctrl-l:select-all' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-/:toggle-preview' \
            --header 'CTRL-l: select-all | CTRL-s: toggle sort | CTRL-/: toggle preview')

    [[ -z "$matches" ]] && return

    # fzf --ansi returns clean "file:line:col:text" lines — exactly quickfix's
    # %f:%l:%c:%m format. Load every selected match, jump to the first, show the list.
    tmpfile=$(mktemp)
    print -r -- "$matches" > "$tmpfile"
    nvim -c 'set errorformat=%f:%l:%c:%m' \
         -c "cfile $tmpfile" \
         -c 'copen' \
         -c 'cfirst'
    rm -f "$tmpfile"
}
alias frg='fag'
alias '\r'='frg'
