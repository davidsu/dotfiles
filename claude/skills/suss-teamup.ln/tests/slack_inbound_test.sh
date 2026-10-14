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
SLACK_OWNER=U0OWNER
readonly THREAD_POSTS="$SUSS_TEAMUP_DIR/thread_posts"
post_to_thread() { printf '%s\n' "$2" >> "$THREAD_POSTS"; }

mkdir -p "$SUSS_TEAMUP_DIR/$SUBJECT/members"
printf '2026-10-13T07:00:15Z\tlaptop.lead\tsay\t@dotfiles.laptop welcome\n2026-10-13T07:00:17Z\tdavid\tsay\techo\n' > "$CHANNEL"
touch "$SUSS_TEAMUP_DIR/$SUBJECT/members/dotfiles.laptop" "$SUSS_TEAMUP_DIR/$SUBJECT/members/david"

fails=0
expect_lines() { # label expected
  local got; got="$(wc -l < "$CHANNEL" | tr -d ' ')"
  [ "$got" = "$2" ] && echo "ok   $1" || { echo "FAIL $1: $got lines, expected $2"; fails=1; }
}
last_line() { tail -1 "$CHANNEL"; }
expect_no_warning() { # label
  grep -q '^:warning:' "$THREAD_POSTS" 2>/dev/null && { echo "FAIL $1: $(grep '^:warning:' "$THREAD_POSTS")"; fails=1; } || echo "ok   $1"
}

deliver_to_channel "$SUBJECT" '```   #1 [07:00:15] laptop.lead (say) @dotfiles.laptop welcome ```' U0OWNER '' >/dev/null
expect_lines "own mirrored block is dropped" 2
deliver_to_channel "$SUBJECT" 'reminder for David _agent: lead.20_' U0OWNER '' top true >/dev/null
expect_lines "an agent's direct post through the connector (owner + footer) is dropped" 2
deliver_to_channel "$SUBJECT" '```   #1 [07:00:15] box.agent (say) @all box block ```' U0OWNER '' thread true >/dev/null
expect_lines "the other machine's bridge posts carry the footer too and are still delivered" 3

deliver_to_channel "$SUBJECT" '```   #1 [07:00:15] box.agent (say) @dotfiles.laptop from the box ```' U0OWNER '' >/dev/null
expect_lines "remote block aimed here is delivered" 4
grep -qF $'\tdavid\task\t@dotfiles.laptop [box.agent] from the box' <(last_line) && echo "ok   delivered as an ask to the local handle, attributed" || { echo "FAIL attribution: $(last_line)"; fails=1; }

deliver_to_channel "$SUBJECT" '```   #5 [07:00:40] box.agent (say) @box.other heads up, @dotfiles.laptop take the laptop half ```' U0OWNER '' >/dev/null
expect_lines "remote line aimed at the other machine's agent but naming one here is delivered" 5
grep -qF $'\tdavid\tsay\t[box.agent] @box.other heads up, @dotfiles.laptop take the laptop half' <(last_line) && echo "ok   delivered to everyone, attributed" || { echo "FAIL remote-handle delivery: $(last_line)"; fails=1; }
expect_no_warning "no warning about a handle that lives on the other machine"

deliver_to_channel "$SUBJECT" '@dotfiles.laptp did you see it' U0OWNER '' >/dev/null
expect_lines "a human's typo is still delivered to everyone" 6
grep -qF 'no agent here is called `dotfiles.laptp`' "$THREAD_POSTS" && echo "ok   the human is warned about the typo" || { echo "FAIL no typo warning: $(cat "$THREAD_POSTS" 2>/dev/null)"; fails=1; }

deliver_to_channel "$SUBJECT" '```   #7 [07:01:00] box.agent (say) @all heads up   #8 [07:01:01] box.agent (say) @box.other private ```' U0OWNER '' >/dev/null
expect_lines "@all delivered, remote-only mention dropped" 7

deliver_to_channel "$SUBJECT" ':warning: the Slack session died (x)' U0OWNER '' >/dev/null
expect_lines "bridge notice is dropped" 7

deliver_to_channel "$SUBJECT" 'plain reply from a phone' U_OTHER 'Someone' >/dev/null
expect_lines "plain reply still delivered" 8

deliver_to_channel "$SUBJECT" '``` my own pasted log line 1 line 2 ```' U0OWNER '' >/dev/null
expect_lines "owner's own code block is delivered" 9
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

prose_message() { # ts text [uid] — one message as the connector prints a channel read
  printf '=== Message from Tester <t@x> (%s) at 2026-10-13 07:00:00 IDT === \nMessage TS: %s\n%s\n\n' "${3:-U0OWNER}" "$1" "$2"
}
prose_thread() { # root reply_ts reply_text — a thread read with one reply
  printf '=== THREAD PARENT MESSAGE ===\nFrom: Tester <t@x> (U0OWNER)\nTime: t\nMessage TS: %s\nroot\n\n=== THREAD REPLIES (1 total) ===\n\n--- Reply 1 of 1 ---\nFrom: Tester <t@x> (U0OWNER)\nTime: t\nMessage TS: %s\n%s\n' "$1" "$2" "$3"
}
read_result() { jq -nc --arg messages "$1" '{messages: $messages, pagination_info: ""}'; }
connector_call() { # fake slack_read_channel: two roots for our subject, one for a longer name
  printf '%s %s\n' "$1" "$2" > "$SUSS_TEAMUP_DIR/last_api_call"
  read_result "$(prose_message 1.000000 "*teamup · $SUBJECT* — reply here"; prose_message 3.000000 "*teamup · ${SUBJECT}_other* — reply here"; prose_message 2.000000 "*teamup · $SUBJECT* — reply here")"
}
expect_text "existing root for this subject is found (newest)" "$(find_existing_root "$SUBJECT")" "2.000000"
expect_text "no root for an unknown subject" "$(find_existing_root nothere)" ""
oldest_asked=$(sed -nE 's/.*"oldest":"([0-9]+)".*/\1/p' "$SUSS_TEAMUP_DIR/last_api_call")
[ -n "$oldest_asked" ] && (( $(date +%s) - oldest_asked >= 86400 && $(date +%s) - oldest_asked < 86460 )) &&
  echo "ok   only roots younger than a day are asked for" || { echo "FAIL oldest= not a day ago: [$oldest_asked]"; fails=1; }
rm -f "$(thread_file "$SUBJECT")" "$(relayed_file "$SUBJECT")"
open_thread "$SUBJECT"
expect_text "open_thread adopts the existing root" "$(cat "$(thread_file "$SUBJECT")")" "2.000000"
[ -s "$(relayed_file "$SUBJECT")" ] && echo "ok   adopted thread relays from now" || { echo "FAIL relayed baseline missing"; fails=1; }

expect_text "a channel with its own slack-channel.{subject} mirrors there" \
  "$(slack_channel_of suss-lead)" "$(cat "$CHANNEL_FILE.suss-lead")"
expect_text "every other channel mirrors to slack-channel" "$(slack_channel_of "$SUBJECT")" "$(cat "$CHANNEL_FILE")"
fake_paired() { # subject root — what one poll's relay returned for this channel: a thread reply, and at the top level a join notice and a message
  local channel oldest; channel="$(slack_channel_of "$1")"; oldest="$(newest_known_reply "$1" "$2")"
  jq -nc --arg thread "$(read_result "$(prose_thread "$2" 5.0 "in thread")")" --argjson thread_args "$(read_thread_args "$channel" "$2" "$oldest")" \
         --arg channel "$(read_result "$(prose_message 6.0 "top level")")" --argjson channel_args "$(read_channel_args "$channel" "$oldest")" \
    '[{name: "slack_read_thread", arguments: $thread_args, result: $thread, error: null}, {name: "slack_read_channel", arguments: $channel_args, result: $channel, error: null}]'
}
merged="$(replies_from_results suss-lead 1.0 "$(fake_paired suss-lead 1.0)")"
expect_text "a dedicated channel relays its thread and its top level, once each" \
  "$(jq -r '[.ok] + [.messages[].ts] | join(" ")' <<<"$merged")" "true 1.0 5.0 6.0"
expect_text "the shared channel reads only the thread" \
  "$(replies_from_results "$SUBJECT" 1.0 "$(fake_paired "$SUBJECT" 1.0)" | jq -r '[.messages[].ts] | join(" ")')" "1.0 5.0"
expect_text "a channel whose read the relay skipped is reported, not silently empty" \
  "$(replies_from_results "$SUBJECT" 1.0 '[]' | jq -r '.ok')" "false"
deliver_to_channel() { echo "$2" >> "$SUSS_TEAMUP_DIR/delivered"; }
deliver_unseen_replies never_engaged_test 1.0 "$merged"
expect_text "the root itself is not delivered" "$(paste -sd, - < "$SUSS_TEAMUP_DIR/delivered")" "in thread,top level"

mkdir -p "$SUSS_TEAMUP_DIR/probe_test" && touch "$SUSS_TEAMUP_DIR/probe_test/.slack.throwaway"
expect_text "a throwaway channel mirrors to slack-channel.throwaway" \
  "$(slack_channel_of probe_test)" "$(cat "$CHANNEL_FILE.throwaway")"
expect_text "a throwaway channel keeps its thread in the channel dir" \
  "$(thread_file probe_test)" "$SUSS_TEAMUP_DIR/probe_test/probe_test.thread"
expect_text "other channels keep their thread in the state dir" \
  "$(thread_file "$SUBJECT")" "$THREAD_STATE/$SUBJECT.thread"
has_dedicated_slack_channel probe_test && { echo "FAIL throwaway counted as dedicated"; fails=1; } ||
  echo "ok   a throwaway channel is not a dedicated one"

mkdir -p "$SUSS_TEAMUP_DIR/gist_test/members"
printf 'pwd=x\ndoing=probing the gist\n' > "$SUSS_TEAMUP_DIR/gist_test/members/opener.a"
expect_text "the root falls back to the opener's --doing" "$(thread_root_text gist_test)" "**teamup · gist_test** — probing the gist"
printf '%s' "$(printf 'é%.0s' {1..300})" > "$SUSS_TEAMUP_DIR/gist_test/.gist"
gist_root="$(thread_root_text gist_test)"
expect_text "the root is the --gist, capped at 240 characters" "${gist_root#*— }" "$(printf 'é%.0s' {1..240})"

exit "$fails"
