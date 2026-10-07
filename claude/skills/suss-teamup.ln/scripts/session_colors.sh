# session_colors.sh — claude's /color palette and the color each team role gets
# (resources/known_team_roles.md). Sourced by teamup-spawn and teamup-wake.

SESSION_COLORS=(red blue green yellow purple orange pink cyan)
UNRESERVED_COLORS=(orange pink cyan)

is_session_color() { [[ " ${SESSION_COLORS[*]} " == *" $1 "* ]]; }

role_color() { # role
  case "$1" in
    lead)   echo blue ;;
    owner)  echo yellow ;;
    keeper) echo red ;;
    *)      echo "${UNRESERVED_COLORS[RANDOM % ${#UNRESERVED_COLORS[@]}]}" ;;
  esac
}

# Found by glob, not `rg --files`: the user's ripgrep config caps files at 10MB, and a
# long-running session's transcript outgrows that.
transcript_color() { # session id — its last /color, empty when it never had one
  local transcripts=("$HOME"/.claude/projects/*/"$1".jsonl)
  [ -f "${transcripts[0]}" ] || return 0
  rg --no-config -o '"type":"agent-color","agentColor":"[^"]*"' "${transcripts[0]}" |
    tail -1 | sed 's/.*:"//;s/"$//' | grep -vx default || true
}
