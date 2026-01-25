# fbw - Bitwarden password manager with fzf
# Usage: fbw (or alias: pw)
# Requires: rbw, fzf
#
# Security: Uses rbw which runs as a background daemon. Vault auto-locks after timeout.
# Session is managed by rbw daemon, not persisted in shell.

function fbw() {
    # Check if rbw is installed
    if ! command -v rbw >/dev/null 2>&1; then
        echo "rbw is not installed. Install with: brew install rbw"
        echo "Then login with the official CLI: bw login"
        return 1
    fi

    # Check if rbw is unlocked, if not unlock it
    if ! rbw unlocked &>/dev/null; then
        echo "Unlocking Bitwarden vault..."
        rbw unlock || return 1
    fi

    local entry
    entry=$(rbw list | \
        fzf --prompt 'Bitwarden> ' \
            --preview '$HOME/.dotfiles/bin/rbw-preview.sh {}' \
            --preview-window 'top:50%:wrap' \
            --bind 'ctrl-p:up' \
            --bind 'ctrl-n:down' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-/:toggle-preview' \
            --bind "ctrl-o:execute-silent(rbw get {} --field uris 2>/dev/null | head -1 | xargs open)" \
            --bind "ctrl-b:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 1)" \
            --bind "ctrl-f:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 2)" \
            --bind "ctrl-g:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 3)" \
            --bind "ctrl-h:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 4)" \
            --bind "ctrl-i:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 5)" \
            --bind "ctrl-j:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 6)" \
            --bind "ctrl-m:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 7)" \
            --bind "ctrl-q:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 8)" \
            --bind "ctrl-v:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 9)" \
            --bind "ctrl-x:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 10)" \
            --bind "B:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 11)" \
            --bind "F:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 12)" \
            --bind "G:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 13)" \
            --bind "H:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 14)" \
            --bind "I:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 15)" \
            --bind "J:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 16)" \
            --bind "M:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 17)" \
            --bind "Q:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 18)" \
            --bind "V:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 19)" \
            --bind "X:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.sh {} 20)" \
            --bind "enter:execute-silent(rbw get {} 2>/dev/null | pbcopy || (rbw get {} --raw | jq -r '.data.number // empty' | pbcopy && echo '✓ Card number copied'))")

    # No output needed - user pressed Esc to exit
}

alias pw='fbw'
