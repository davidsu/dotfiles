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

_print_gdc_usage() {
  cat <<'USAGE'
Usage: gdc [-h|--help] [<commit> [<commit>]]
       gdc <commit>..<commit>

Open a Fugitive-style file list of what changed, then `dd` on a file to diff it.

  gdc                   branch point (merge-base of origin/HEAD and HEAD) vs working tree
  gdc <commit>          <commit> vs working tree
  gdc <a> <b>           commit vs commit (order doesn't matter, sorted by commit time)
  gdc <a>..<b>          same as above

Examples:
  gdc HEAD~1            what I changed since the last commit
  gdc abc123~1 abc123   a commit vs its parent
  gdc main feature      two branches

Keys in the list: dd diff, <CR> open, o split, q close all, g? help
USAGE
}

# gdc - Git Diff Commits (Fugitive-style UI via :Gdc)
gdiffbranch() {
  [[ "$1" == "-h" || "$1" == "--help" ]] && { _print_gdc_usage; return 0; }
  _require_git_repo gdc || return 1

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
