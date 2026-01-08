#!/bin/zsh

# Navigation Aliases
alias jd='cd $DOTFILES'

# Global Aliases
alias -g G='| grep -i'
alias -g V=' > /tmp/t && nvim /tmp/t -c '\''nmap q :q!<cr>'\'''
alias -g PJ='package.json'
alias -g IB='--inspect-brk'

# ls (BSD/macOS): colorized output + classify + one entry per line
alias ls='ls -GF1'
alias la='ls -lAh'

alias vim='nvim'

# Git Aliases
alias gst='git status'
alias glv='git log --max-count=500 --name-only V'

# Process
alias killbg='kill $(sed -E '\''s/\[([[:digit:]]+)\].*/%\1/g'\'' <<< $(jobs))'

# Javascript Ninja
alias showPackage = jq '.scripts' package.json

# Git Status in Vim (interactive git status using vim-fugitive)
function gsv() {
    gitstatus=$(git status)
    if [[ $gitstatus =~ 'both modified' ]]; then
       echo 'this flow is likely broken :)'
        nvim -u $HOME/.dotfiles/config/nvim/init_for_gsv.vim \
           -c 'let g:tmp=search("both modi")' \
           -c 'call feedkeys("\<C-n>dv:Gstatus\<cr>\<C-w>K".g:tmp."G") ' \
           $(git rev-parse --show-toplevel)/.git/index
     else
      nvim -c 'call feedkeys(":Git\<cr>]mdd\<C-K>") '
    fi
}

alias gsva='gsv'
