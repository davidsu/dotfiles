#!/bin/zsh

# Git Aliases
alias gst='git status'
alias glv='git log --max-count=500 --name-only V'

# Helpers
_require_git_repo() {
  git rev-parse --show-toplevel >/dev/null 2>&1 || {
    echo "$1: not in a git repo" >&2
    return 1
  }
}

_open_fugitive_status() {
  nvim -c 'call feedkeys(":Git\<cr>]mdd\<C-K>")'
}

# gsv - Git Status in Vim (interactive git status using vim-fugitive)
gsv() {
  _require_git_repo gsv || return 1

  if git diff --name-only --diff-filter=U | grep -q .; then
    echo 'merge conflict flow (likely broken)'
    nvim \
      -c 'let g:tmp=search("both modi")' \
      -c 'call feedkeys("\\<C-n>dv:Gstatus\\<cr>\\<C-w>K".g:tmp."G") ' \
      "$(git rev-parse --show-toplevel)/.git/index"
  else
    _open_fugitive_status
  fi
}

alias gsva='gsv'

# gdc - Git Diff Commits (Fugitive-style UI via :Gdc)
# Usage: gdc <commit1> <commit2> 
gdiffbranch() {
  _require_git_repo gdc || return 1

  [[ -z "$1" ]] && { echo "Usage: gdc <commit1> <commit2>" >&2; return 1; }
  nvim -c "GDiffBranch $*"
}
alias gdc='gdiffbranch'

# gco - Git CheckOut, worktree-aware:
# check out a branch, or cd to the worktree that already has it
gco() {
  _require_git_repo gco || return 1

  local branch=$1
  [[ -z "$branch" ]] && { echo "Usage: gco <branch>" >&2; return 1; }

  local wt
  wt=$(git worktree list --porcelain | awk -v b="refs/heads/$branch" '
    /^worktree / { path = $2 }
    $0 == "branch " b { print path; exit }
  ')

  if [[ -n "$wt" ]]; then
    cd "$wt"
  else
    git checkout "$branch"
  fi
}
alias gitcheckout='gco'
