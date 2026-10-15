#!/usr/bin/env bash
# Every teamup-spawn colors its peer (David, 2026-10-15: "no such thing as spawn and not color"): the iTerm tab
# through its tty, claude's `/color` typed with iTerm's per-session `write text`, which takes no focus.
# Stubbed terminal, ps and claude transcript; no real keystrokes.
set -uo pipefail

readonly TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
export SUSS_TEAMUP_DIR="$SANDBOX/teamup" HOME="$SANDBOX/home"
unset CLAUDE_CODE_SESSION_ID ITERM_SESSION_ID TEAMUP_AFTER_HANDLE

readonly SPAWN="$TESTS_DIR/../scripts/teamup-spawn"
readonly PAINTED="$SANDBOX/painted.log" TYPED="$SANDBOX/typed.log" SCRIPTS="$SANDBOX/scripts.log"
readonly TRANSCRIPT="$HOME/.claude/projects/p/peer-session.jsonl"
readonly STUBS="$SANDBOX/bin"
mkdir -p "$STUBS" "$HOME/.dotfiles/bin" "$HOME/.claude/sessions" "$(dirname "$TRANSCRIPT")"
printf '{"sessionId":"peer-session"}' > "$HOME/.claude/sessions/4242.json"
touch "$TRANSCRIPT"

stub() { printf '#!/usr/bin/env bash\n%s\n' "$2" > "$1"; chmod +x "$1"; } # path body
stub "$STUBS/term_spawn" '[ "$1" = --resolve ] && echo iterm || echo FAKE-SESSION'
stub "$STUBS/ps" '[[ "$*" == *pid=,comm=* ]] && echo "4242 claude" || printf "claude\ncodex\n"'
stub "$HOME/.dotfiles/bin/iterm_tab_style" "echo \"\$*\" >> '$PAINTED'"
stub "$STUBS/osascript" "
if [ \"\$1\" = - ]; then script=\"\$(cat)\"; shift; else script=\"\$2\"; shift 2; fi
printf '%s\n' \"\$script\" >> '$SCRIPTS'
[[ \"\$script\" == *'return tty'* ]] && echo /dev/ttys999
[ -n \"\${2:-}\" ] || exit 0
echo \"\$2\" >> '$TYPED'
[[ \"\$2\" == '/color '* ]] && echo '{\"type\":\"agent-color\",\"agentColor\":\"'\"\${2#/color }\"'\"}' >> '$TRANSCRIPT'
exit 0"
export PATH="$STUBS:$PATH"

fails=0
expect_text() { # label got expected
  [ "$2" = "$3" ] && echo "ok   $1" || { echo "FAIL $1: got [$2], expected [$3]"; fails=1; }
}
spawn() { rm -f "$PAINTED" "$TYPED" "$SCRIPTS"; "$SPAWN" "$@" >/dev/null 2>&1; }

spawn claude subj --as peer.a --color green
expect_text "claude: the tab is painted" "$(cat "$PAINTED")" "--session FAKE-SESSION --color green"
expect_text "claude: /color is typed into its session" "$(cat "$TYPED")" "/color green"
expect_text "claude: no script activates an app or sends keystrokes" \
  "$(grep -cE 'activate|keystroke|System Events' "$SCRIPTS")" "0"

spawn claude subj --as peer.b --role lead
expect_text "claude --role lead: the role color, tab and /color" "$(cat "$PAINTED") | $(cat "$TYPED")" \
  "--session FAKE-SESSION --color blue | /color blue"

spawn codex subj --as peer.c --color red
expect_text "codex: the tab is painted" "$(cat "$PAINTED")" "--session FAKE-SESSION --color red"

for flag in --no-steal --no-color; do
  "$SPAWN" claude subj --as peer.d "$flag" >/dev/null 2>&1
  expect_text "$flag is gone: spawn refuses it" "$?" "1"
done

exit "$fails"
