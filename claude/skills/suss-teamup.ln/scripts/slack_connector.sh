# Sourced by teamup-slack: the claude.ai Slack connector, driven from bash through a headless
# `claude -p` relay (the connector is only reachable from a Claude session). No Slack tokens.
# The caller defines die() and may set CONNECTOR_LOG for per-call cost lines.

readonly CONNECTOR_MODEL="${TEAMUP_SLACK_MODEL:-haiku}"
readonly CONNECTOR_TOOL_PREFIX="mcp__claude_ai_Slack__"
readonly CONNECTOR_MAX_TURNS=8
readonly CONNECTOR_TIMEOUT_SECONDS=120
readonly CONNECTOR_IDENTITY="${XDG_STATE_HOME:-$HOME/.local/state}/suss-teamup/slack/connector"
mkdir -p "$CONNECTOR_IDENTITY"

relay_pacing() { # [ordered] — posts must land in the order written; reads may run at once
  [ "${1:-}" = ordered ] && echo 'strictly in the listed order, one call per turn, waiting for each result before the next' ||
    echo 'all in the same turn'
}

relay_prompt() { # calls-json [ordered]
  printf 'You are a relay with no judgment. Call every tool listed below exactly once, %s, passing each "arguments" object verbatim as the tool input. Never alter, add or drop an argument, never call any other tool, never retry a failed call. When every result is in, reply with the single word: done.\n\nCALLS:\n%s\n' "$(relay_pacing "${2:-}")" "$1"
}

with_full_tool_names() { # calls-json → the same calls under the names the relay session sees
  jq -c --arg prefix "$CONNECTOR_TOOL_PREFIX" 'map(.name |= $prefix + .)' <<<"$1"
}

tool_names_of() { # calls-json → comma-separated full tool names
  jq -r --arg prefix "$CONNECTOR_TOOL_PREFIX" '[.[].name | $prefix + .] | unique | join(",")' <<<"$1"
}

run_relay() { # calls-json [ordered] → stream-json events
  env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_ENTRYPOINT \
    timeout "$CONNECTOR_TIMEOUT_SECONDS" claude -p --model "$CONNECTOR_MODEL" --output-format stream-json --verbose \
      --max-turns "$CONNECTOR_MAX_TURNS" --allowedTools "$(tool_names_of "$1")" -- "$(relay_prompt "$(with_full_tool_names "$1")" "${2:-}")" < /dev/null 2>>"${CONNECTOR_LOG:-/dev/null}"
}

log_relay_cost() { # events
  [ -n "${CONNECTOR_LOG:-}" ] || return 0
  jq -r 'select(.type=="result") | "\(now | strftime("%F %T")) relay: \(.num_turns) turns, \(.duration_ms) ms, $\(.total_cost_usd)"' <<<"$1" >> "$CONNECTOR_LOG" 2>/dev/null
}

pair_calls_with_results() { # events → [{name, arguments, result, error}], tool_use joined to tool_result by id
  jq -s --arg prefix "$CONNECTOR_TOOL_PREFIX" '
    [.[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")] as $uses
    | [.[] | select(.type=="user") | .message.content[]? | select(.type=="tool_result")
        | {id: .tool_use_id, is_error: (.is_error // false),
           text: (.content | if type=="array" then map(.text // "") | join("") else (. // "") end)}] as $results
    | [$uses[] | . as $use | ($results[] | select(.id == $use.id)) as $result
        | {name: ($use.name | ltrimstr($prefix)), arguments: $use.input,
           result: (if $result.is_error then null else $result.text end),
           error: (if $result.is_error then $result.text else null end)}]' <<<"$1"
}

connector_calls() { # calls-json [{name, arguments}] [ordered] → [{name, arguments, result, error}]; a call the relay skipped is simply absent
  local events; events="$(run_relay "$1" "${2:-}")"
  log_relay_cost "$events"
  [ -n "$events" ] || { echo '[]'; return 1; }
  pair_calls_with_results "$events"
}

result_of() { # paired-json name arguments-json → result text, or exit 1 with the error on stderr
  local match
  match="$(jq -c --arg name "$2" --argjson args "$3" 'map(select(.name == $name and .arguments == $args)) | first // empty' <<<"$1")"
  [ -n "$match" ] || { echo "connector: no result for $2 $3" >&2; return 1; }
  jq -r 'if .result != null then .result else ("connector: " + .name + " failed: " + (.error // "unknown") | halt_error(1)) end' <<<"$match"
}

connector_call() { # name arguments-json → result text
  local calls; calls="$(jq -nc --arg name "$1" --argjson args "$2" '[{name: $name, arguments: $args}]')"
  result_of "$(connector_calls "$calls")" "$1" "$2"
}

# --- the connector answers in prose; these turn it back into {ok, messages:[{ts, user, username, text, thread_ts}]} ---

connector_text_to_records() { # messages-text → one "ts␟user␟name␟via_connector␟text" line per message
  awk '
    function flush() { if (ts != "") printf "%s\x1f%s\x1f%s\x1f%s\x1f%s\n", ts, uid, name, via, trim(text); ts = ""; text = ""; via = 0 }
    function trim(s) { gsub(/^ +| +$/, "", s); gsub(/  +/, " ", s); return s }
    function author(s) { uid = ""; name = s; if (match(s, /\(([UWB][A-Z0-9]+)\)$/)) { uid = substr(s, RSTART + 1, RLENGTH - 2); name = substr(s, 1, RSTART - 1) } sub(/ <[^>]*> *$/, "", name); sub(/ +$/, "", name) }
    /^=== Message from .* at .* ===/ { flush(); s = $0; sub(/^=== Message from /, "", s); sub(/ at [^(]* ===.*$/, "", s); author(s); collecting = 0; next }
    /^(--- Reply [0-9]+ of [0-9]+ ---|=== THREAD PARENT MESSAGE ===|=== THREAD REPLIES)/ { flush(); collecting = 0; next }
    /^From: / && !collecting { author(substr($0, 7)); next }
    /^Time: / && !collecting { next }
    /^Message TS: / { ts = substr($0, 13); collecting = 1; next }
    !collecting { next }
    /^(Reactions|Files|Thread|Edited): / { collecting = 0; next }
    /^\*Sent using\* <@/ { via = 1; next }
    { text = text " " $0 }
    END { flush() }'
}

connector_messages_json() { # messages-text [thread_ts] → {ok:true, messages:[...]}
  connector_text_to_records <<<"$1" |
    jq -R -s --arg thread "${2:-}" '{ok: true, messages: [split("\n")[] | select(length > 0) | split("\u001f")
      | {ts: .[0], user: .[1], username: .[2], via_connector: (.[3] == "1"), text: .[4]} + (if $thread == "" then {} else {thread_ts: $thread} end)]}'
}

messages_text_of() { # read-tool result json → its messages prose
  jq -r '.messages // empty' <<<"$1" 2>/dev/null
}

connector_failure_json() { # error → {ok:false, error}
  jq -nc --arg error "$1" '{ok: false, error: $error}'
}

# --- identity: who the connector posts as ---

owner_id_file() { printf '%s/owner.id' "$CONNECTOR_IDENTITY"; }
team_url_file() { printf '%s/team.url' "$CONNECTOR_IDENTITY"; }

fetch_owner_id() {
  connector_call slack_read_user_profile '{"response_format":"detailed"}' | jq -r '.result // empty' | sed -n 's/^User ID: //p'
}

load_connector_identity() { # sets SLACK_OWNER, SLACK_TEAM_URL (empty until the first post reveals it)
  SLACK_OWNER="$(cat "$(owner_id_file)" 2>/dev/null || true)"
  if [ -z "$SLACK_OWNER" ]; then
    SLACK_OWNER="$(fetch_owner_id)"
    [ -n "$SLACK_OWNER" ] || die "the Slack connector did not answer (is 'claude.ai Slack' connected? run: claude mcp list)"
    printf '%s' "$SLACK_OWNER" > "$(owner_id_file)"
  fi
  SLACK_TEAM_URL="$(cat "$(team_url_file)" 2>/dev/null || true)"
}

remember_team_url() { # message_link — https://{team}.slack.com/archives/… → https://{team}.slack.com/
  [ -s "$(team_url_file)" ] && return 0
  SLACK_TEAM_URL="$(sed -E 's#^(https://[^/]+/).*#\1#' <<<"$1")"
  printf '%s' "$SLACK_TEAM_URL" > "$(team_url_file)"
}
