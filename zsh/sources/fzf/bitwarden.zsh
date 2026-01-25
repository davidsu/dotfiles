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
            --preview '$HOME/.dotfiles/bin/rbw-preview.js {}' \
            --preview-window 'top:50%:wrap' \
            --bind 'ctrl-p:up' \
            --bind 'ctrl-n:down' \
            --bind 'ctrl-s:toggle-sort' \
            --bind 'ctrl-/:toggle-preview' \
            --bind "ctrl-o:execute-silent(rbw get {} --field uris 2>/dev/null | head -1 | xargs open)" \
            --bind "ctrl-b:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 1)" \
            --bind "ctrl-f:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 2)" \
            --bind "ctrl-g:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 3)" \
            --bind "ctrl-h:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 4)" \
            --bind "ctrl-j:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 5)" \
            --bind "ctrl-q:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 6)" \
            --bind "ctrl-v:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 7)" \
            --bind "ctrl-x:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 8)" \
            --bind "ctrl-r:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 9)" \
            --bind "ctrl-t:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 10)" \
            --bind "ctrl-y:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 11)" \
            --bind "ctrl-l:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 12)" \
            --bind "ctrl-d:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 13)" \
            --bind "alt-a:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 14)" \
            --bind "alt-b:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 15)" \
            --bind "alt-c:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 16)" \
            --bind "alt-d:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 17)" \
            --bind "alt-e:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 18)" \
            --bind "alt-f:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 19)" \
            --bind "alt-g:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 20)" \
            --bind "alt-h:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 21)" \
            --bind "alt-i:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 22)" \
            --bind "alt-j:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 23)" \
            --bind "alt-k:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 24)" \
            --bind "alt-l:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 25)" \
            --bind "alt-m:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 26)" \
            --bind "alt-n:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 27)" \
            --bind "alt-o:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 28)" \
            --bind "alt-p:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 29)" \
            --bind "alt-q:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 30)" \
            --bind "alt-r:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 31)" \
            --bind "alt-s:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 32)" \
            --bind "alt-t:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 33)" \
            --bind "alt-u:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 34)" \
            --bind "alt-v:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 35)" \
            --bind "alt-w:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 36)" \
            --bind "alt-x:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 37)" \
            --bind "alt-y:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 38)" \
            --bind "alt-z:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-index.js {} 39)" \
            --bind "enter:execute-silent(rbw get {} 2>/dev/null | pbcopy || (rbw get {} --raw | jq -r '.data.number // empty' | pbcopy && echo '✓ Card number copied'))")

    # No output needed - user pressed Esc to exit
}

alias pw='fbw'
