#!/bin/zsh

# Prefix-based history search
# up-line-or-beginning-search: If the cursor is at the end of the line, it searches 
# backwards for commands starting with the current line. Otherwise, it moves up.
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Bind Ctrl+P/N (matches dotfilesold)
bindkey "^p" up-line-or-beginning-search
bindkey "^n" down-line-or-beginning-search

# Keybindings
bindkey '^G' push-line
bindkey '^H' run-help


