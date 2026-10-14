# Slack session rotation killed every bridge, 2026-10-14

## What happened

- 07:33 IDT: Slack rotated David's web session. The `xoxc` token and `d` cookie in the laptop
  keychain (`slack-mcp-xoxc` / `slack-mcp-xoxd`) and the box's copy under
  `~/.config/suss-teamup/` all answered `invalid_auth`.
- Every `teamup-slack` poller on both machines died the same second: 16 laptop channels wrote
  `.slack.broken`, the box's 6 bridges too. Nothing reached Slack; David's replies in the threads
  reached no agent. The three 08:30 launchd reminders would have failed the same way.
- The failure is silence: a dead bridge looks exactly like a quiet channel. lead.20 noticed only
  because a reminder it was about to post needed the session, 5 minutes in.
- 07:34 lead.20 reached David through the claude.ai Slack connector (`mcp__claude_ai_Slack__slack_send_message`
  into #suss-lead), which authenticates through claude.ai and had survived. It read the box's
  channel over ssh every 10 minutes and relayed by hand.
- 08:12 David, at the keyboard: "we need a different solution. likely claude.ai slack mcp based.
  this 'got my tokens from my browser' isn't good enough. I don't have access to api keys at this
  moment, don't want it if possible."
- 08:20 slack.bridge found the connector can be driven from plain bash through Claude Code's own
  OAuth token and an undocumented Anthropic proxy (1 s per call). lead.20 vetoed it as the same
  class of harvested credential David had just rejected; David was asked and did not flip it.
- 08:37 the rebuilt bridge (one daemon, `claude -p --model haiku` as the transport) proved both
  directions on a throwaway channel: 19 s laptop→Slack, under a minute Slack→laptop.

## What to do differently

- A bridge that depends on a credential the user did not mint for it will die on a schedule the
  user does not control. Build on what the harness already authenticates.
- Silence must be loud: the bridge posts `.slack.broken` to the thread AND says it on the channel
  after 5 minutes of failed polls. Check `teamup-slack status` and `bridge.log` before trusting a
  quiet channel.
- Reaching David when the bridges are down: the connector tool from any Claude session, into
  #suss-lead, ending `_agent: <handle>_`.
