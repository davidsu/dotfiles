# Shortcut to dotfiles directory
export DOTFILES="$HOME/.dotfiles"

# reload zsh configuration
function reload() {
    # Source all .zsh files in the zsh directory, excluding entry point files (*.home.zsh)
    for f in "$DOTFILES"/zsh/*.zsh; do
        if [[ "$f" != *.home.zsh ]]; then
            source "$f"
        fi
    done
}

# Initial load
reload

# Alias for manual reload
alias a='reload'
