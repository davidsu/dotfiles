#!/bin/bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
dir=$(pwd | awk -F/ '{if(NF<=2) print $0; else print "../"$(NF-1)"/"$NF}')

# Git info (matches Starship prompt style)
git_info=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git rev-parse --short HEAD 2>/dev/null)

  status=""
  # Staged files
  staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  [ "$staged" -gt 0 ] && status+="\e[33m✚\e[0m"
  # Modified files
  modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  [ "$modified" -gt 0 ] && status+="\e[32m✭\e[0m"
  # Untracked files
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null | head -1)
  [ -n "$untracked" ] && status+="\e[36m✱\e[0m"

  git_info=" | \e[1;34m(\e[0m\e[1;34m${branch}\e[0m${status}\e[1;34m)\e[0m"
fi

printf "\e[38;2;130;210;195m%s\e[0m | \e[38;2;195;160;210mContext: %.1f%%\e[0m | \e[90m%s\e[0m%b" "$model" "$used" "$dir" "$git_info"
