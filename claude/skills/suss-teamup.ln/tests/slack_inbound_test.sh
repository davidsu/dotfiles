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

exit "$fails"
