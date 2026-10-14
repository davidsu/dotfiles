# Slack through the claude.ai connector (fallback route)

`slack-post` is the primary route. Use this one when `slack-post` fails with `invalid_auth`:
David's Slack web session rotated and the keychain tokens died with it. **Never refresh those
tokens yourself** (David, 2026-10-14: agents harvesting his browser tokens is out). Tell David
the script is down, then post through the connector.

Load the tools once:

```
ToolSearch select:mcp__claude_ai_Slack__slack_send_message,mcp__claude_ai_Slack__slack_get_file_upload_url,mcp__claude_ai_Slack__slack_complete_file_upload,mcp__claude_ai_Slack__slack_read_thread,mcp__claude_ai_Slack__slack_read_channel
```

What changes against `slack-post`:

| `slack-post`                       | connector                                                              |
|------------------------------------|------------------------------------------------------------------------|
| draft markup (`[label](url)`)      | text posts take standard markdown; file comments take mrkdwn `<url\|label>` |
| `check` renders the draft          | paste the draft as a blockquote in your reply, labels visible, URLs hidden |
| `--update TS`, `delete`            | none: no edit, no delete. Read twice before you send                   |
| no footer                          | every post ends with `Sent using @Claude`; David knows                 |
| `verify` reads the post back       | you read it back yourself (below)                                      |

## ✍️ Text

`slack_send_message` with `channel_id`, `message`, and `thread_ts` for a reply. Links are
`[label](url)`. The signature line `_agent: <handle>_` is part of `message`.

## 🎬 Video or image

Three calls. The message is the file's `initial_comment`; there is no separate text post.

1. `slack_get_file_upload_url` with `filename` and `content_length` = the exact byte count
   (`stat -f %z clip.webm`). **No `alt_txt`**: with it Slack stores the file with no mimetype,
   `slack_complete_file_upload` still says success, and nothing is ever posted (measured
   2026-10-14, six uploads of the same webm: every one with `alt_txt` died, every one without
   got an inline player, in a channel and as a thread reply, with or without `title`).
2. POST the bytes. The URL goes in a shell variable, byte for byte; `Content-Type` names the
   file type (`video/webm`, `video/mp4`, `image/png`). Expect `OK - <bytes>` and `http=200`.
   ```
   URL='<upload url>' && curl -sS -w '\nhttp=%{http_code}\n' -X POST "$URL" -H 'Content-Type: video/webm' --data-binary @clip.webm
   ```
3. `slack_complete_file_upload` with `file_id`, `channel_id`, `thread_ts` for a reply, and
   `initial_comment` = the whole message in mrkdwn: `<url|label>` links, one line per Slack
   line, `_agent: <handle>_` last. `title` is optional; the filename is the default title.

Read it back about 5 s later with `slack_read_thread` (`response_format: detailed`), or
`slack_read_channel` for a top-level post. The message must be there, and its `Files:` line
must carry the mimetype: `Files: clip.webm (ID: F…, video/webm, 1.6 MB)`. That mimetype is
what gives the inline player.

If the message is missing, or the mimetype slot between the commas is empty, the upload is
dead. **Do not post the file's link in a text message**: Slack renders it as a bare file card
with the raw file id in the text (the 2026-10-14 failure). Start again from step 1.

Proof thread (throwaway channel): https://base44workspace.slack.com/archives/C0C8PB41Z37/p1791980296843409
