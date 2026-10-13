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
SLACK_OWNER=U_OWNER
SLACK_DESTINATION=C_TEST
readonly API_LOG="$SUSS_TEAMUP_DIR/api_calls"
slack_api() { printf '%s\n' "$*" >> "$API_LOG"; echo '{"ok":true,"ts":"7.000000"}'; }
for subject in "$DEDICATED" "$SHARED" "$THROWAWAY"; do printf 1.000000 > "$(thread_file "$subject")"; done

post_message_args() { grep '^chat.postMessage' "$API_LOG"; }
mirror_line() { # subject recv-line — what mirror_channel_to_slack does with one line
  : > "$API_LOG"
  post_code_block "$1" "$2" "$(poster_for "$1" "$2")"
}

mirror_line "$DEDICATED" "  #3 [07:00:00] tester (say) status: all green [top]"
expect_text "a [top] line in a dedicated channel is posted without thread_ts" "$(post_message_args | grep -c thread_ts)" "0"
expect_text "the top-level post's ts is recorded, so the inbound poll skips it" "$(tail -1 "$(posted_file "$DEDICATED")")" "7.000000"
mirror_line "$DEDICATED" "  #4 [07:00:01] tester (say) routine chatter"
expect_text "a plain line in a dedicated channel stays in the thread" "$(post_message_args | grep -o 'thread_ts=1.000000')" "thread_ts=1.000000"
mirror_line "$SHARED" "  #3 [07:00:02] tester (say) noise [top]"
expect_text "a [top] line in the shared channel falls back to the thread" "$(post_message_args | grep -o 'thread_ts=1.000000')" "thread_ts=1.000000"
mirror_line "$THROWAWAY" "  #3 [07:00:03] tester (say) probe [top]"
expect_text "a [top] line in a throwaway channel is posted top-level" "$(post_message_args | grep -c thread_ts)" "0"

printf '2026-10-13T07:02:00Z\tdavid\task\t@tester [box.agent] ping-from-box\n' >> "$SUSS_TEAMUP_DIR/$DEDICATED/channel.tsv"
remote_line=$(line_count "$DEDICATED")
expect_text "the tag does not break the reply cross-back to another machine" \
  "$(with_reply_crossback "$DEDICATED" "  #9 [07:02:10] tester (ack) re:#$remote_line pong [top]")" \
  "  #9 [07:02:10] tester (ack) re:#$remote_line @box.agent pong [top]"

slack_api() { # fake: one thread reply; top level has a plain message, one that roots its own thread, and our own top-level post
  case "$1" in
    conversations.replies) echo '{"ok":true,"messages":[{"ts":"1.000000","user":"U_OWNER","text":"root"},{"ts":"5.0","thread_ts":"1.000000","user":"U_OWNER","text":"in thread"}]}' ;;
    conversations.history) echo '{"ok":true,"messages":[{"ts":"6.0","user":"U_OWNER","text":"top level"},{"ts":"8.0","thread_ts":"8.0","user":"U_OWNER","text":"rooted"},{"ts":"7.000000","user":"U_OWNER","text":"```   #3 [07:00:00] tester (say) status: all green [top] ```"}]}' ;;
  esac
}
before=$(line_count "$DEDICATED")
deliver_unseen_replies "$DEDICATED" 1.000000 "$(fetch_unseen_replies "$DEDICATED" 1.000000)" >/dev/null
delivered() { tail -n +"$(( before + 1 ))" "$SUSS_TEAMUP_DIR/$1/channel.tsv" | cut -f2,3,4 | paste -sd'|' -; }
expect_text "a thread reply arrives untagged, David's top-level messages arrive tagged, our own top-level post does not come back" \
  "$(delivered "$DEDICATED")" $'david\tsay\tin thread|david\tsay\ttop level [top]|david\tsay\trooted [top]'
before=$(line_count "$THROWAWAY")
deliver_unseen_replies "$THROWAWAY" 1.000000 "$(fetch_unseen_replies "$THROWAWAY" 1.000000)" >/dev/null
expect_text "a throwaway channel relays #suss-throwaway's top level too" "$(delivered "$THROWAWAY" | grep -o '\[top\]' | wc -l | tr -d ' ')" "2"
before=$(line_count "$SHARED")
deliver_unseen_replies "$SHARED" 1.000000 "$(fetch_unseen_replies "$SHARED" 1.000000)" >/dev/null
expect_text "the shared channel still reads only its thread" "$(delivered "$SHARED")" $'david\tsay\tin thread'

exit "$fails"
