# How `send` works, and the Slack traps it avoids

Auth: David's Slack web session from the keychain, `slack-mcp-xoxc` (token) and `slack-mcp-xoxd`
(cookie, sent as `Cookie: d=…`), the same as `teamup-slack`. Code: `scripts/slack_session.py`.

| Step        | Call                                                                                  |
|-------------|---------------------------------------------------------------------------------------|
| Post        | `chat.postMessage` with `rich_text` blocks + a plain `text` fallback, unfurl off       |
| With image  | `files.getUploadURLExternal` → upload bytes → `files.completeUploadExternal` with the draft as `initial_comment` (mrkdwn); then poll until the message shows up |
| Edit        | `chat.update` with blocks, unfurl off, and the message's existing `file_ids`            |
| Read back   | 5s later: `conversations.replies` (or `.history`); delete previews with `chat.deleteAttachment`; compare link and @tag counts with the draft |
| @tags       | `users.list` once per run; a name must match exactly one user                          |

Traps:

- A text-only `chat.update` escapes links (`<url|label>` shows literally) and still returns `ok`.
- `chat.update` can attach a link preview even with unfurl off; `chat.deleteAttachment` removes it.
- The Slack MCP `conversations_add_message` has no unfurl flags.
- Building JSON in zsh: `echo "$JSON"` turns `\n` into a real newline and jq rejects it.

Unverified: whether Slack's composer links pasted `[text](url)`, and saving a Slack draft
instead of posting (`slack_send_message_draft` in the claude.ai connector).
