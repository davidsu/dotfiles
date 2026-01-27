#!/bin/zsh

# Navigation Aliases
alias jd='cd $DOTFILES'

# Global Aliases
alias -g G='| grep -i'
alias -g V=' > /tmp/t && nvim /tmp/t -c '\''nmap q :q!<cr>'\'''
alias -g PJ='package.json'
alias -g IB='--inspect-brk'
alias -g NO='--name-only'

# ls (BSD/macOS): colorized output + classify + one entry per line
alias ls='ls -GF1'
alias la='ls -Ah'

alias vim='nvim'

# Git Aliases
alias gst='git status'
alias glv='git log --max-count=500 --name-only V'

# Process
alias killbg='kill $(sed -E '\''s/\[([[:digit:]]+)\].*/%\1/g'\'' <<< $(jobs))'

# Javascript Ninja
alias showPackage="jq '.scripts' package.json"

# Git Status in Vim (interactive git status using vim-fugitive)
function gsv() {
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "gsv: not in a git repo" >&2
    return 1
  fi

  if git diff --name-only --diff-filter=U | grep -q .; then
    echo 'this flow is likely broken :)'
    nvim \
      -c 'let g:tmp=search("both modi")' \
      -c 'call feedkeys("\\<C-n>dv:Gstatus\\<cr>\\<C-w>K".g:tmp."G") ' \
      "$(git rev-parse --show-toplevel)/.git/index"
  else
    nvim -c 'call feedkeys(":Git\<cr>]mdd\<C-K>") '
  fi
}

alias gsva='gsv'

function goto(){
    #dirname removes the filename from path
    #realpath gives the path to the file, if symlinked it gives the path to the actual file, not the link
    cd $(dirname $(realpath $(which $1)))
}

# Claude Code Aliases
alias cyolo='claude --dangerously-skip-permissions'

# Markdown viewer
alias mdview='nvim --headless -c "MarkdownPreview" -c "sleep 4000m | qa"'
