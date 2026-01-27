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

_require_clean_worktree() {
  git diff-index --quiet HEAD -- 2>/dev/null || {
    echo "$1: uncommitted changes, commit or stash first" >&2
    return 1
  }
}

_valid_commit() {
  git rev-parse "$1" >/dev/null 2>&1
}

_commit_timestamp() {
  git log -1 --format=%ct "$1"
}

_order_commits_by_time() {
  local ts1=$(_commit_timestamp "$1")
  local ts2=$(_commit_timestamp "$2")

  if [[ $ts1 -lt $ts2 ]]; then
    echo "$1" "$2"
  else
    echo "$2" "$1"
  fi
}

_open_fugitive_diff() {
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
    _open_fugitive_diff
  fi
}

alias gsva='gsv'

# gdc - Git Diff Commits with Fugitive UI
# Usage: gdc <commit1> <commit2>  (order doesn't matter)
gdc() {
  _require_git_repo gdc || return 1
  _require_clean_worktree gdc || return 1

  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: gdc <commit1> <commit2>" >&2
    return 1
  fi

  for commit in "$1" "$2"; do
    if ! _valid_commit "$commit"; then
      echo "gdc: invalid commit '$commit'" >&2
      return 1
    fi
  done

  local commits=($(_order_commits_by_time "$1" "$2"))
  local earlier="${commits[1]}"
  local later="${commits[2]}"

  local original_ref=$(git symbolic-ref -q HEAD || git rev-parse HEAD)
  local temp_branch="temp-diff-$$"

  git checkout -b "$temp_branch" "$later" || return 1
  git reset "$earlier"

  _open_fugitive_diff

  git checkout -f "${original_ref#refs/heads/}"
  git branch -D "$temp_branch"
}
