#!/usr/bin/env bash
# `--top`: the CLI tags the line, the bridge posts it top-level only in a Slack channel this teamup channel owns,
# and the user's top-level messages come back tagged. Throwaway channel, no Slack, no keychain.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export XDG_STATE_HOME="$SUSS_TEAMUP_DIR/state"
export TEAMUP_SLACK=off
unset CLAUDE_CODE_SESSION_ID TEAMUP_SESSION CODEX_THREAD_ID TEAMUP_SESSION_NAME
trap 'rm -rf "$SUSS_TEAMUP_DIR"' EXIT

readonly CLI="$TESTS_DIR/../scripts/teamup"
readonly DEDICATED=suss-lead
readonly SHARED=shared_test
readonly THROWAWAY=probe_test

fails=0
expect_text() { # label got expected
  [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }
}
last_body() { tail -1 "$SUSS_TEAMUP_DIR/$1/channel.tsv" | cut -f4; }
line_count() { wc -l < "$SUSS_TEAMUP_DIR/$1/channel.tsv" | tr -d ' '; }

for subject in "$DEDICATED" "$SHARED" "$THROWAWAY"; do "$CLI" join "$subject" --as david --pwd slack-bridge --doing "the bridge" >/dev/null; done
"$CLI" join "$DEDICATED" --as tester --pwd /t --doing test >/dev/null
"$CLI" join "$SHARED" --as tester --pwd /t --doing test >/dev/null
"$CLI" join "$THROWAWAY" --as tester --pwd /t --doing test --throwaway >/dev/null

"$CLI" say "$DEDICATED" --as tester --top -- "status: all green" >/dev/null
expect_text "say --top appends the tag in a dedicated channel" "$(last_body "$DEDICATED")" "status: all green [top]"
"$CLI" say "$DEDICATED" --as tester -- "routine chatter" >/dev/null
expect_text "say without --top is untouched" "$(last_body "$DEDICATED")" "routine chatter"
"$CLI" ask "$DEDICATED" --as tester --to david --top -- "merge now?" >/dev/null
expect_text "ask --top keeps the @target first and the tag last" "$(last_body "$DEDICATED")" "@david merge now? [top]"
"$CLI" ack "$DEDICATED" --as tester --re 1 --top -- "done" >/dev/null
expect_text "ack --top keeps re:#N first, so reply-wakes still parse" "$(last_body "$DEDICATED")" "re:#1 done [top]"
"$CLI" say "$THROWAWAY" --as tester --top -- "probe" >/dev/null
expect_text "a throwaway channel owns #suss-throwaway, so --top is allowed" "$(last_body "$THROWAWAY")" "probe [top]"

before=$(line_count "$SHARED")
refusal="$("$CLI" say "$SHARED" --as tester --top -- "noise" 2>&1 >/dev/null)"; code=$?
expect_text "--top in the shared #suss-teamup is refused with exit 2" "$code" "2"
expect_text "the refusal names the missing slack-channel file" "$(grep -o "slack-channel.$SHARED" <<<"$refusal")" "slack-channel.$SHARED"
expect_text "a refused --top posts nothing" "$(line_count "$SHARED")" "$before"
"$CLI" ask "$SHARED" --as tester --top -- "q" >/dev/null 2>&1; expect_text "ask --top refused there too" "$?" "2"
"$CLI" ack "$SHARED" --as tester --re 1 --top >/dev/null 2>&1; expect_text "ack --top refused there too" "$?" "2"

source "$TESTS_DIR/../scripts/teamup-slack"
SLACK_OWNER=U0OWNER
SLACK_DESTINATION=C_TEST
readonly API_LOG="$SUSS_TEAMUP_DIR/api_calls"
connector_calls() { # fake relay: every post lands as ts 7.000000
  jq -c '.[].arguments' <<<"$1" >> "$API_LOG"
  jq -c 'map(. + {result: "{\"message_link\":\"https://t.slack.com/archives/C/p7000000\",\"message_context\":{\"message_ts\":\"7.000000\"}}", error: null})' <<<"$1"
}
for subject in "$DEDICATED" "$SHARED" "$THROWAWAY"; do printf 1.000000 > "$(thread_file "$subject")"; done

post_message_args() { cat "$API_LOG"; }
mirror_line() { # subject recv-line — what the daemon does with one line
  : > "$API_LOG"
  post_code_block "$1" "$2" "$(poster_for "$1" "$2")"
  flush_posts
}

mirror_line "$DEDICATED" "  #3 [07:00:00] tester (say) status: all green [top]"
expect_text "a [top] line in a dedicated channel is posted without thread_ts" "$(post_message_args | grep -c thread_ts)" "0"
expect_text "the top-level post's ts is recorded, so the inbound poll skips it" "$(tail -1 "$(posted_file "$DEDICATED")")" "7.000000"
mirror_line "$DEDICATED" "  #4 [07:00:01] tester (say) routine chatter"
expect_text "a plain line in a dedicated channel stays in the thread" "$(post_message_args | grep -o '"thread_ts":"1.000000"')" '"thread_ts":"1.000000"'
mirror_line "$SHARED" "  #3 [07:00:02] tester (say) noise [top]"
expect_text "a [top] line in the shared channel falls back to the thread" "$(post_message_args | grep -o '"thread_ts":"1.000000"')" '"thread_ts":"1.000000"'
mirror_line "$THROWAWAY" "  #3 [07:00:03] tester (say) probe [top]"
expect_text "a [top] line in a throwaway channel is posted top-level" "$(post_message_args | grep -c thread_ts)" "0"

prose_message() { # ts text [extra-line] — one message as the connector prints a channel read
  printf '=== Message from Tester <t@x> (U0OWNER) at 2026-10-13 07:00:00 IDT === \nMessage TS: %s\n%s\n%s\n' "$1" "$2" "${3:-}"
}
prose_thread() { # root — a thread read with one reply
  printf '=== THREAD PARENT MESSAGE ===\nFrom: Tester <t@x> (U0OWNER)\nTime: t\nMessage TS: %s\nroot\n\n=== THREAD REPLIES (1 total) ===\n\n--- Reply 1 of 1 ---\nFrom: Tester <t@x> (U0OWNER)\nTime: t\nMessage TS: 5.0\nin thread\n' "$1"
}
read_result() { jq -nc --arg messages "$1" '{messages: $messages, pagination_info: ""}'; }
fake_paired() { # subject root — the relay's answer: one thread reply; top level has a plain message, one that roots its own thread, and our own top-level post
  local channel oldest; channel="$(slack_channel_of "$1")"; oldest="$(newest_known_reply "$1" "$2")"
  jq -nc --arg thread "$(read_result "$(prose_thread "$2")")" --argjson thread_args "$(read_thread_args "$channel" "$2" "$oldest")" \
         --arg channel "$(read_result "$(prose_message 6.0 "top level"; prose_message 8.0 "rooted" "Thread: 1 replies (latest: t)"; prose_message 7.000000 '```   #3 [07:00:00] tester (say) status: all green [top] ```')")" \
         --argjson channel_args "$(read_channel_args "$channel" "$oldest")" \
    '[{name: "slack_read_thread", arguments: $thread_args, result: $thread, error: null}, {name: "slack_read_channel", arguments: $channel_args, result: $channel, error: null}]'
}
before=$(line_count "$DEDICATED")
deliver_unseen_replies "$DEDICATED" 1.000000 "$(replies_from_results "$DEDICATED" 1.000000 "$(fake_paired "$DEDICATED" 1.000000)")" >/dev/null
delivered() { tail -n +"$(( before + 1 ))" "$SUSS_TEAMUP_DIR/$1/channel.tsv" | cut -f2,3,4 | paste -sd'|' -; }
expect_text "a thread reply arrives untagged, David's top-level messages arrive tagged, our own top-level post does not come back" \
  "$(delivered "$DEDICATED")" $'david\tsay\tin thread|david\tsay\ttop level [top]|david\tsay\trooted [top]'
before=$(line_count "$THROWAWAY")
deliver_unseen_replies "$THROWAWAY" 1.000000 "$(replies_from_results "$THROWAWAY" 1.000000 "$(fake_paired "$THROWAWAY" 1.000000)")" >/dev/null
expect_text "a throwaway channel relays #suss-throwaway's top level too" "$(delivered "$THROWAWAY" | grep -o '\[top\]' | wc -l | tr -d ' ')" "2"
before=$(line_count "$SHARED")
deliver_unseen_replies "$SHARED" 1.000000 "$(replies_from_results "$SHARED" 1.000000 "$(fake_paired "$SHARED" 1.000000)")" >/dev/null
expect_text "the shared channel still reads only its thread" "$(delivered "$SHARED")" $'david\tsay\tin thread'

exit "$fails"
