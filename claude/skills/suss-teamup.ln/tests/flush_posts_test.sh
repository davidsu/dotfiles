#!/usr/bin/env bash
# flush_posts: a queued post leaves bridge.queue only once Slack confirmed it. A burst larger than one
# relay can carry spans several flushes in order, a relay that posts nothing keeps the queue intact,
# and a post Slack keeps refusing dies after MAX_POST_ATTEMPTS with a log line. Throwaway dir, no Slack.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export XDG_STATE_HOME="$SUSS_TEAMUP_DIR/state"
export TEAMUP_SLACK=off
unset CLAUDE_CODE_SESSION_ID TEAMUP_SESSION CODEX_THREAD_ID TEAMUP_SESSION_NAME
trap 'rm -rf "$SUSS_TEAMUP_DIR"' EXIT

readonly SUBJECT=flush_test
mkdir -p "$SUSS_TEAMUP_DIR/$SUBJECT/members"
source "$TESTS_DIR/../scripts/teamup-slack"
SLACK_OWNER=U0OWNER
printf 1.000000 > "$(thread_file "$SUBJECT")"

fails=0
expect_text() { # label got expected
  [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }
}

readonly API_LOG="$SUSS_TEAMUP_DIR/api_calls"
readonly BATCH_SIZES="$SUSS_TEAMUP_DIR/batch_sizes"
RELAY_MODE=lands
landed_result() { jq -nc --arg ts "$1" '{message_link: "https://t.slack.com/archives/C/p1", message_context: {message_ts: $ts}} | tostring'; }
connector_calls() { # fake relay: every call lands with its own ts, unless RELAY_MODE says otherwise
  jq -r '.[].arguments.message' <<<"$1" >> "$API_LOG"
  jq 'length' <<<"$1" >> "$BATCH_SIZES"
  case "$RELAY_MODE" in
    silent) echo '[]'; return 1 ;;
    poison) jq -c 'to_entries | map(.value + (if (.value.arguments.message | test("poison")) then {result: null, error: "msg_too_long"} else {result: ("{\"message_link\":\"https://t.slack.com/archives/C/p1\",\"message_context\":{\"message_ts\":\"" + (.key | tostring) + ".000000\"}}"), error: null} end))' <<<"$1" ;;
    *) jq -c 'to_entries | map(.value + {result: ("{\"message_link\":\"https://t.slack.com/archives/C/p1\",\"message_context\":{\"message_ts\":\"" + (.key | tostring) + ".000000\"}}"), error: null})' <<<"$1" ;;
  esac
}

reset() { : > "$API_LOG"; : > "$BATCH_SIZES"; : > "$SEND_QUEUE"; rm -f "$(posted_file "$SUBJECT")"; }
queue_lines() { wc -l < "$SEND_QUEUE" | tr -d ' '; }
posted_count() { [ -f "$(posted_file "$SUBJECT")" ] && wc -l < "$(posted_file "$SUBJECT")" | tr -d ' ' || echo 0; }
queue_burst() { local n; for n in $(seq 1 "$1"); do post_to_thread "$SUBJECT" "post $n"; done; }

reset
queue_burst 19
flush_posts >/dev/null; flush_posts >/dev/null; flush_posts >/dev/null
expect_text "a 19-post burst lands entirely across relays" "$(posted_count)" "19"
expect_text "no relay carries more posts than the turn cap allows" "$(sort -n "$BATCH_SIZES" | tail -1) $(paste -sd, "$BATCH_SIZES")" "7 7,7,5"
expect_text "the posts reach Slack in the order they were queued" "$(paste -sd' ' "$API_LOG")" "$(seq -f 'post %g' 1 19 | paste -sd' ' -)"
expect_text "the queue is empty once every post is confirmed" "$(queue_lines)" "0"

reset
queue_burst 3
RELAY_MODE=silent
flush_posts >/dev/null 2>&1
expect_text "a relay that posted nothing leaves the queue intact" "$(queue_lines)" "3"
expect_text "nothing is recorded as posted after a silent relay" "$(posted_count)" "0"
RELAY_MODE=lands
flush_posts >/dev/null
expect_text "the next flush delivers what the silent relay skipped" "$(posted_count) $(queue_lines)" "3 0"

reset
post_to_thread "$SUBJECT" "before"
post_to_thread "$SUBJECT" "poison pill"
post_to_thread "$SUBJECT" "after"
RELAY_MODE=poison
log="$(flush_posts 2>&1; flush_posts 2>&1)"
expect_text "a refused post stays queued while its neighbours land" "$(posted_count) $(queue_lines)" "2 1"
expect_text "the refused post is retried first on the next flush" "$(tail -1 "$API_LOG")" "poison pill"
log="$log
$(flush_posts 2>&1)"
expect_text "a post refused 3 times is dropped from the queue" "$(queue_lines)" "0"
expect_text "the drop is logged with the connector's error" "$(grep -c 'post lost on flush_test: poison pill after 3 attempts.*msg_too_long' <<<"$log")" "1"

exit "$fails"
