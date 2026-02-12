#!/bin/zsh

# Navigation
alias jd='cd $DOTFILES'

# Global Aliases
alias -g G='| grep -i'
alias -g V=' > /tmp/t && nvim /tmp/t -c '\''nmap q :q!<cr>'\'''
alias -g PJ='package.json'
alias -g IB='--inspect-brk'
alias -g NO='--name-only'
alias -g NS='--name-status'

# ls (BSD/macOS): colorized output + classify + one entry per line
alias ls='ls -GF1'
alias la='ls -Ah'

alias vim='nvim'

# Process
alias killbg='kill $(sed -E '\''s/\[([[:digit:]]+)\].*/%\1/g'\'' <<< $(jobs))'

# Javascript
alias showPackage="jq '.scripts' package.json"

# goto - cd to directory containing a command
goto() {
  cd $(dirname $(realpath $(which $1)))
}

# Claude Code
alias cyolo='claude --dangerously-skip-permissions'
alias cy='claude --dangerously-skip-permissions'
alias cvim='nvim -c "ClaudeConnect"'

# Markdown viewer
alias mdview='nvim --headless -c "MarkdownPreview"'

# Beads vim viewer
alias bvim='nvim -c "Beads"'
alias vbeads='nvim -c "Beads"'
