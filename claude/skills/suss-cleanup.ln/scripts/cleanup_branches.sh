#!/usr/bin/env bash
set -eo pipefail

readonly PROTECTED_NAME_REGEX="${SUSS_CLEANUP_PROTECTED_REGEX:-do.?not.?delete|dont.?delete|backup|preserve|keep.?me}"

execute=false
[[ "${1:-}" == "--execute" ]] && execute=true

candidates=()
protected_branches=()
deleted_branches=()
removed_worktrees=()
failures=()

ensure_prerequisites() {
  command -v gh >/dev/null || { echo "gh CLI not found on PATH" >&2; exit 1; }
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "not inside a git repository" >&2; exit 1; }
}

has_open_pr() {
  grep -qxF "$1" <<<"$open_pr_branches"
}

is_protected() {
  grep -qiE "$PROTECTED_NAME_REGEX" <<<"$1"
}

worktree_path_for_branch() {
  git worktree list --porcelain | awk -v target="refs/heads/$1" '
    /^worktree / { path = substr($0, 10) }
    $1 == "branch" && $2 == target { print path }
  '
}

classify_branches() {
  local branch
  while read -r branch; do
    [[ "$branch" == "$current_branch" ]] && continue
    [[ "$branch" == "$default_branch" ]] && continue
    if is_protected "$branch"; then
      protected_branches+=("$branch")
      continue
    fi
    has_open_pr "$branch" && continue
    candidates+=("$branch")
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/)
}

remove_worktree() {
  local branch="$1" worktree="$2" output
  if [[ "$worktree" == "$primary_worktree" ]]; then
    failures+=("$branch: checked out in primary worktree — not removing")
    return 1
  fi
  if output=$(git worktree remove "$worktree" 2>&1); then
    removed_worktrees+=("$worktree")
    return 0
  fi
  failures+=("$branch: worktree remove failed — $output")
  return 1
}

delete_branch() {
  local branch="$1" output
  if output=$(git branch -D "$branch" 2>&1); then
    deleted_branches+=("$branch")
    return 0
  fi
  failures+=("$branch: branch delete failed — $output")
}

delete_candidate() {
  local branch="$1" worktree
  worktree=$(worktree_path_for_branch "$branch")
  if [[ -n "$worktree" ]]; then
    remove_worktree "$branch" "$worktree" || return
  fi
  delete_branch "$branch"
}

print_list() {
  local item
  for item in "$@"; do
    echo "  - $item"
  done
}

print_plan() {
  echo "Default branch: $default_branch   Current branch: ${current_branch:-<detached>}"
  echo
  if (( ${#protected_branches[@]} )); then
    echo "Protected (kept, matched /$PROTECTED_NAME_REGEX/):"
    print_list "${protected_branches[@]}"
    echo
  fi
  if (( ${#candidates[@]} == 0 )); then
    echo "Nothing to delete — every local branch has an open PR or is protected."
    return
  fi
  echo "Branches with NO open PR (${#candidates[@]} to delete):"
  local branch worktree
  for branch in "${candidates[@]}"; do
    worktree=$(worktree_path_for_branch "$branch")
    [[ -n "$worktree" ]] && echo "  - $branch   [worktree: $worktree]" || echo "  - $branch"
  done
}

print_results() {
  echo
  echo "===== RESULTS ====="
  (( ${#removed_worktrees[@]} )) && { echo "Removed worktrees:"; print_list "${removed_worktrees[@]}"; }
  (( ${#deleted_branches[@]} )) && { echo "Deleted branches:"; print_list "${deleted_branches[@]}"; }
  if (( ${#failures[@]} )); then
    echo "Failures:"
    print_list "${failures[@]}"
  fi
  echo "Done: ${#deleted_branches[@]} branch(es), ${#removed_worktrees[@]} worktree(s), ${#failures[@]} failure(s)."
}

ensure_prerequisites

open_pr_branches=$(gh pr list --state open --limit 1000 --json headRefName --jq '.[].headRefName' | sort -u)
current_branch=$(git symbolic-ref --quiet --short HEAD || true)
default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)
[[ -z "$default_branch" ]] && default_branch=main
primary_worktree=$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}')

classify_branches
print_plan

if ! $execute; then
  echo
  echo "DRY RUN — no changes made. Re-run with --execute to apply."
  exit 0
fi

(( ${#candidates[@]} == 0 )) && exit 0

for candidate in "${candidates[@]}"; do
  delete_candidate "$candidate" || true
done
print_results
