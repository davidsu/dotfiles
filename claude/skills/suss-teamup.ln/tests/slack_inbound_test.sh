#!/usr/bin/env bash
# Exercises teamup-slack's inbound filter against a throwaway channel: no Slack, no keychain.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
export SUSS_TEAMUP_DIR="$(mktemp -d)"
export XDG_STATE_HOME="$SUSS_TEAMUP_DIR/state"
readonly SUBJECT=inbound_test
readonly CHANNEL="$SUSS_TEAMUP_DIR/$SUBJECT/channel.tsv"
trap 'rm -rf "$SUSS_TEAMUP_DIR"' EXIT

source "$TESTS_DIR/../scripts/teamup-slack"
SLACK_OWNER=U_OWNER
post_to_thread() { :; }

mkdir -p "$SUSS_TEAMUP_DIR/$SUBJECT/members"
printf '2026-10-13T07:00:15Z\tlaptop.lead\tsay\t@dotfiles.laptop welcome\n2026-10-13T07:00:17Z\tdavid\tsay\techo\n' > "$CHANNEL"
touch "$SUSS_TEAMUP_DIR/$SUBJECT/members/dotfiles.laptop" "$SUSS_TEAMUP_DIR/$SUBJECT/members/david"

fails=0
expect_lines() { # label expected
  local got; got="$(wc -l < "$CHANNEL" | tr -d ' ')"
  [ "$got" = "$2" ] && echo "ok   $1" || { echo "FAIL $1: $got lines, expected $2"; fails=1; }
}
last_line() { tail -1 "$CHANNEL"; }

deliver_to_channel "$SUBJECT" '```   #1 [07:00:15] laptop.lead (say) @dotfiles.laptop welcome ```' U_OWNER '' >/dev/null
expect_lines "own mirrored block is dropped" 2

deliver_to_channel "$SUBJECT" '```   #1 [07:00:15] box.agent (say) @dotfiles.laptop from the box ```' U_OWNER '' >/dev/null
expect_lines "remote block aimed here is delivered" 3
grep -qF $'\tdavid\task\t@dotfiles.laptop [box.agent] from the box' <(last_line) && echo "ok   delivered as an ask to the local handle, attributed" || { echo "FAIL attribution: $(last_line)"; fails=1; }

deliver_to_channel "$SUBJECT" '```   #7 [07:01:00] box.agent (say) @all heads up   #8 [07:01:01] box.agent (say) @box.other private ```' U_OWNER '' >/dev/null
expect_lines "@all delivered, remote-only mention dropped" 4

deliver_to_channel "$SUBJECT" ':warning: the Slack session died (x)' U_OWNER '' >/dev/null
expect_lines "bridge notice is dropped" 4

deliver_to_channel "$SUBJECT" 'plain reply from a phone' U_OTHER 'Someone' >/dev/null
expect_lines "plain reply still delivered" 5

deliver_to_channel "$SUBJECT" '``` my own pasted log line 1 line 2 ```' U_OWNER '' >/dev/null
expect_lines "owner's own code block is delivered" 6
grep -qF $'\tdavid\tsay\t``` my own pasted log' <(last_line) && echo "ok   delivered as a say from david" || { echo "FAIL own block: $(last_line)"; fails=1; }


printf '2026-10-13T07:02:00Z\tdavid\task\t@dotfiles.laptop [box.agent] ping-from-box\n' >> "$CHANNEL"
remote_line=$(wc -l < "$CHANNEL" | tr -d ' ')
expect_text() { # label got expected
  [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2]"; fails=1; }
}
expect_text "reply to a remote message names its author" \
  "$(with_reply_crossback "$SUBJECT" "  #9 [07:02:10] dotfiles.laptop (ack) re:#$remote_line pong")" \
  "  #9 [07:02:10] dotfiles.laptop (ack) re:#$remote_line @box.agent pong"
expect_text "reply already naming the author is left alone" \
  "$(with_reply_crossback "$SUBJECT" "  #9 [07:02:10] dotfiles.laptop (say) re #$remote_line @box.agent pong")" \
  "  #9 [07:02:10] dotfiles.laptop (say) re #$remote_line @box.agent pong"
expect_text "reply to a local message is left alone" \
  "$(with_reply_crossback "$SUBJECT" "  #9 [07:02:10] dotfiles.laptop (ack) re:#1 thanks")" \
  "  #9 [07:02:10] dotfiles.laptop (ack) re:#1 thanks"
expect_text "non-reply is left alone" \
  "$(with_reply_crossback "$SUBJECT" "  #9 [07:02:10] dotfiles.laptop (say) plain")" \
  "  #9 [07:02:10] dotfiles.laptop (say) plain"

SLACK_DESTINATION=C_TEST
slack_api() { # fake conversations.history: two roots, one for our subject, one for a longer name
  printf '%s\n' "$*" > "$SUSS_TEAMUP_DIR/last_api_call"
  printf '{"ok":true,"messages":[{"ts":"1.000000","text":"*teamup · %s* — reply here"},{"ts":"3.000000","text":"*teamup · %s_other* — reply here"},{"ts":"2.000000","text":"*teamup · %s* — reply here"}]}' "$SUBJECT" "$SUBJECT" "$SUBJECT"
}
expect_text "existing root for this subject is found (newest)" "$(find_existing_root "$SUBJECT")" "2.000000"
expect_text "no root for an unknown subject" "$(find_existing_root nothere)" ""
oldest_asked=$(sed -nE 's/.*oldest=([0-9]+).*/\1/p' "$SUSS_TEAMUP_DIR/last_api_call")
[ -n "$oldest_asked" ] && (( $(date +%s) - oldest_asked >= 86400 && $(date +%s) - oldest_asked < 86460 )) &&
  echo "ok   only roots younger than a day are asked for" || { echo "FAIL oldest= not a day ago: [$oldest_asked]"; fails=1; }
rm -f "$(thread_file "$SUBJECT")" "$(relayed_file "$SUBJECT")"
open_thread "$SUBJECT"
expect_text "open_thread adopts the existing root" "$(cat "$(thread_file "$SUBJECT")")" "2.000000"
[ -s "$(relayed_file "$SUBJECT")" ] && echo "ok   adopted thread relays from now" || { echo "FAIL relayed baseline missing"; fails=1; }

expect_text "a channel with its own slack-channel.{subject} mirrors there" \
  "$(slack_channel_of suss-lead)" "$(cat "$CHANNEL_FILE.suss-lead")"
expect_text "every other channel mirrors to slack-channel" "$(slack_channel_of "$SUBJECT")" "$(cat "$CHANNEL_FILE")"
slack_api() { echo "$1" >> "$SUSS_TEAMUP_DIR/unfollow_calls"; }
unfollow_unless_engaged suss-lead
[ ! -s "$SUSS_TEAMUP_DIR/unfollow_calls" ] && echo "ok   a dedicated channel's thread is never unfollowed" || { echo "FAIL dedicated thread unfollowed"; fails=1; }
printf 9.000000 > "$(thread_file never_engaged_test)"
unfollow_unless_engaged never_engaged_test
grep -qx subscriptions.thread.remove "$SUSS_TEAMUP_DIR/unfollow_calls" && echo "ok   other threads are still unfollowed" || { echo "FAIL shared thread not unfollowed"; fails=1; }

exit "$fails"
