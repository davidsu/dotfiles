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
            --bind "ctrl-b:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-b)" \
            --bind "ctrl-f:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-f)" \
            --bind "ctrl-g:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-g)" \
            --bind "ctrl-h:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-h)" \
            --bind "ctrl-j:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-j)" \
            --bind "ctrl-q:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-q)" \
            --bind "ctrl-v:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-v)" \
            --bind "ctrl-x:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-x)" \
            --bind "ctrl-r:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-r)" \
            --bind "ctrl-t:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-t)" \
            --bind "ctrl-y:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-y)" \
            --bind "ctrl-l:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-l)" \
            --bind "ctrl-d:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} ctrl-d)" \
            --bind "alt-a:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-a)" \
            --bind "alt-b:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-b)" \
            --bind "alt-c:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-c)" \
            --bind "alt-d:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-d)" \
            --bind "alt-e:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-e)" \
            --bind "alt-f:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-f)" \
            --bind "alt-g:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-g)" \
            --bind "alt-h:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-h)" \
            --bind "alt-i:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-i)" \
            --bind "alt-j:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-j)" \
            --bind "alt-k:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-k)" \
            --bind "alt-l:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-l)" \
            --bind "alt-m:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-m)" \
            --bind "alt-n:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-n)" \
            --bind "alt-o:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-o)" \
            --bind "alt-p:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-p)" \
            --bind "alt-q:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-q)" \
            --bind "alt-r:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-r)" \
            --bind "alt-s:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-s)" \
            --bind "alt-t:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-t)" \
            --bind "alt-u:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-u)" \
            --bind "alt-v:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-v)" \
            --bind "alt-w:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-w)" \
            --bind "alt-x:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-x)" \
            --bind "alt-y:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-y)" \
            --bind "alt-z:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.js {} alt-z)" \
            --bind "enter:execute-silent(rbw get {} 2>/dev/null | pbcopy || (rbw get {} --raw | jq -r '.data.number // empty' | pbcopy && echo '✓ Card number copied'))")

    # No output needed - user pressed Esc to exit
}

alias pw='fbw'
