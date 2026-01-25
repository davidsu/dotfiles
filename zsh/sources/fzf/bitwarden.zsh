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
            --bind "$(bun $HOME/.dotfiles/bin/rbw-fields.js)" \
            --bind "enter:execute-silent(rbw get {} 2>/dev/null | pbcopy || (rbw get {} --raw | jq -r '.data.number // empty' | pbcopy && echo '✓ Card number copied'))")

    # No output needed - user pressed Esc to exit
}

alias pw='fbw'
