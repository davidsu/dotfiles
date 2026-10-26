# Sourced by teamup-slack: what a Slack reply becomes on the teamup channel.
# Needs BASE, HANDLE, TEAMUP, HERE, TOP_LEVEL_TAG, SLACK_OWNER, post_to_thread, relayed_file, engaged_file.

unescape_slack() { sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g'; }

agent_handles() { # subject
  ls -A "$BASE/$1/members" 2>/dev/null | grep -v "^$HANDLE$"
}

slack_author_name() { # user_id name_from_message
  [ -n "$2" ] && { printf '%s' "$2"; return 0; }
  connector_call slack_read_user_profile "$(jq -nc --arg user "$1" '{user_id: $user, response_format: "concise"}')" |
    jq -r '.result // empty' | head -1 | sed 's/ (.*$//'
}

first_word() { awk 'NR==1 { print $1; exit }' <<<"$1"; }

live_handle_for() { # subject typed — exact, else with "." and "-" interchangeable, since the user types them alike
  local typed="${2%[,:;.]}"
  agent_handles "$1" | grep -xF -- "$typed" && return 0
  agent_handles "$1" | awk -v want="$(tr . - <<<"$typed")" '{ h = $0; gsub(/\./, "-", h) } h == want { print; found = 1; exit } END { exit !found }'
}

is_agent_code_block() { [[ "$1" == '```'* ]] && grep -qE '#[0-9]+ \[[0-9:]{8}\] [^ ]+ \([a-z]+\) ' <<<"$1"; }

is_bridge_notice() { [[ "$1" == ':warning: '* || "$1" == ':white_check_mark: '* || "$1" == '_channel is empty'* ]]; }

is_word_lead() { # word — "lead", any case, "@" and trailing punctuation optional
  local typed="${1#@}"
  [ "$(tr '[:upper:]' '[:lower:]' <<<"${typed%[,:;.]}")" = lead ]
}

lead_handles() { agent_handles "$1" | grep '^lead'; }

ask_each() { # subject handles text
  local handle
  while read -r handle; do
    "$TEAMUP" ask "$1" --as "$HANDLE" --to "$handle" -- "$3" || return 1
  done <<<"$2"
}

warn_unknown_handle() { # subject handle — a person mistyped it and can retype
  post_to_thread "$1" ":warning: no agent here is called \`$2\` — sent to everyone instead. Live handles: $(agent_handles "$1" | paste -sd, - | sed 's/,/, /g')" || true
}

deliver_text() { # subject text attribution — a text opening with a live handle aims at it, "@" optional; "lead" aims at every lead*; any other @handle goes to everyone
  local word target body leads
  word="$(first_word "$2")"
  body="${2#"$word"}"
  if is_word_lead "$word" && leads="$(lead_handles "$1")"; then
    ask_each "$1" "$leads" "$3${body# }"
    return
  fi
  target="$(live_handle_for "$1" "${word#@}")"
  if [ -n "$target" ]; then
    "$TEAMUP" ask "$1" --as "$HANDLE" --to "$target" -- "$3${body# }"
    return
  fi
  [[ "$word" == @* ]] && warn_unknown_handle "$1" "${word#@}"
  "$TEAMUP" say "$1" --as "$HANDLE" -- "$3$2"
}

saved_blob_path() { # slack_read_file result → the path Claude Code saved the file's bytes to
  grep -oE '(saved to|\[Image: source:) /[^ ,]+' <<<"$1" | head -1 | sed -E 's/^(saved to|\[Image: source:) //; s/\]$//'
}

download_slack_file() { # subject file_id → local path
  local blob dest
  blob="$(saved_blob_path "$(connector_call slack_read_file "$(jq -nc --arg id "$2" '{file_id: $id}')")")"
  [ -f "$blob" ] || return 1
  dest="$BASE/$1/files/$2.${blob##*.}"
  mkdir -p "$(dirname "$dest")" && mv "$blob" "$dest" && printf '%s' "$dest"
}

with_files_downloaded() { # subject text — each "[slack file ID]" becomes "[file: local path]", the same marker teamup-telegram uses
  local text="$2" file_id path marker
  for file_id in $(grep -oE '\[slack file F[A-Z0-9]+\]' <<<"$2" | sed -E 's/^\[slack file |\]$//g'); do
    path="$(download_slack_file "$1" "$file_id")" && marker="[file: $path]" || marker="[Slack file $file_id: download failed, read it with slack_read_file]"
    text="${text//"[slack file $file_id]"/$marker}"
  done
  printf '%s' "$text"
}

is_agent_direct_post() { # author_id via_connector text — an agent wrote it to Slack through the connector under the owner's name (a notice for the user, not a reply)
  [ "$1" = "$SLACK_OWNER" ] && [ "$2" = true ] && ! is_agent_code_block "$3"
}

deliver_to_channel() { # subject text author_id author_name [origin: top|thread] [via_connector] — a top-level message is tagged so an agent can answer in kind
  local text attribution=""
  text="$(unescape_slack <<<"$2")"
  is_bridge_notice "$text" && return 0
  is_agent_direct_post "$3" "${6:-false}" "$text" && return 0
  is_agent_code_block "$text" && return 0
  text="$(with_files_downloaded "$1" "$text")"
  [ "${5:-thread}" = top ] && text="$text$TOP_LEVEL_TAG"
  if [ "$3" = "$SLACK_OWNER" ]; then
    touch "$(engaged_file "$1")"
    "$HERE/teamup-focus" on >/dev/null
  else attribution="[slack: $(slack_author_name "$3" "$4")] "; fi
  deliver_text "$1" "$text" "$attribution"
}

deliver_unseen_replies() { # subject root replies — a message is top-level when it is not a reply (no thread_ts, or it roots its own thread)
  local skip ts author author_name origin via text
  skip="$(cat "$(posted_file "$1")" "$(relayed_file "$1")" 2>/dev/null)"
  while IFS=$'\x1f' read -r ts author author_name origin via text; do
    grep -qxF "$ts" <<<"$skip" && continue
    deliver_to_channel "$1" "$text" "$author" "$author_name" "$origin" "$via" && echo "$ts" >> "$(relayed_file "$1")"
  done < <(jq -r --arg root "$2" '.messages[] | select(.ts != $root and ((.subtype // "") | startswith("channel_") | not)) |
    [(.ts), (.user // .bot_id), (.bot_profile.name // .username // ""), (if (.thread_ts // .ts) == .ts then "top" else "thread" end), ((.via_connector // false) | tostring), (.text | gsub("[\n\t]"; " "))] | join("\u001f")' <<<"$3")
}
