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
  staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  [ "$staged" -gt 0 ] && status+="\e[33m✚\e[0m"
  modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  [ "$modified" -gt 0 ] && status+="\e[32m✭\e[0m"
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null | head -1)
  [ -n "$untracked" ] && status+="\e[36m✱\e[0m"

  git_info=" | \e[1;34m(\e[0m\e[1;34m${branch}\e[0m${status}\e[1;34m)\e[0m"
fi

printf "\e[38;2;130;210;195m%s\e[0m | \e[38;2;195;160;210mContext: %.1f%%\e[0m | \e[90m%s\e[0m%b" "$model" "$used" "$dir" "$git_info"

# Session banner (set via `!banner` script, keyed on Claude's PID)
# Claude runs this script directly, so PPID = Claude's PID
banner_file="/tmp/claude-banners/$PPID.txt"
[[ -f "$banner_file" ]] || exit 0
banner_text=$(<"$banner_file")
[[ -z "$banner_text" ]] && exit 0

# Hash-based palette (matches pi session-banner colors)
palettes=(
  "40;80;120"    # steel
  "120;40;80"    # berry
  "80;100;40"    # olive
  "100;50;120"   # plum
  "40;100;90"    # teal
  "130;70;30"    # amber
  "60;60;120"    # indigo
  "120;50;50"    # brick
  "50;90;60"     # forest
  "90;60;100"    # mauve
)

hash=0
for (( i=0; i<${#banner_text}; i++ )); do
  char_val=$(printf '%d' "'${banner_text:$i:1}")
  hash=$(( ((hash << 5) - hash + char_val) & 0x7FFFFFFF ))
done
rgb="${palettes[$((hash % ${#palettes[@]}))]}"

cols=120
label="▌ $banner_text"
label_len=${#label}
left_pad=$(( (cols - label_len) / 2 ))
right_pad=$(( cols - left_pad - label_len ))
printf "\n\e[48;2;%sm\e[1;38;2;255;255;255m%*s%s%*s\e[0m" "$rgb" "$left_pad" "" "$label" "$right_pad" ""
