# Sourced by teamup-slack and teamup-slack-watch: the user's Slack web session (xoxc + d cookie).
# The caller defines die().

keychain_secret() { security find-generic-password -a "$USER" -s "$1" -w 2>/dev/null; }

slack_api() { # method [curl data args...]
  local method="$1"; shift
  curl -s --max-time 20 -X POST "https://slack.com/api/$method" \
    -H "Cookie: d=$SLACK_COOKIE" --data-urlencode "token=$SLACK_TOKEN" "$@"
}

load_slack_credentials() { # sets SLACK_TOKEN SLACK_COOKIE SLACK_OWNER SLACK_TEAM_URL
  SLACK_TOKEN="$(keychain_secret slack-mcp-xoxc)"
  SLACK_COOKIE="$(keychain_secret slack-mcp-xoxd)"
  [ -n "$SLACK_TOKEN" ] && [ -n "$SLACK_COOKIE" ] ||
    die "no Slack session in the keychain (slack-mcp-xoxc / slack-mcp-xoxd)"
  local identity; identity="$(slack_api auth.test)"
  [ "$(jq -r '.ok' <<<"$identity")" = true ] ||
    die "Slack rejected the session: $(jq -r '.error // "unreachable"' <<<"$identity") — re-copy the xoxc/xoxd tokens into the keychain"
  SLACK_OWNER="$(jq -r '.user_id' <<<"$identity")"
  SLACK_TEAM_URL="$(jq -r '.url' <<<"$identity")"
}
