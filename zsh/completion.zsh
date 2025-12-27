#!/bin/zsh

# Initialize Zsh completion system
autoload -Uz compinit
compinit

# Case-insensitive tab completion
# 'm:{a-zA-Z}={A-Za-z}' allows matching lowercase to uppercase and vice versa
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending

# Verbose completion output
zstyle ':completion:*' verbose yes

