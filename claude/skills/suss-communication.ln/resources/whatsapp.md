# WhatsApp

Send through WhatsApp Web in **Chrome**. Text goes through `mcp__playwright-chrome__*` (David's
logged-in Chrome, extension mode). Attachments switch to `mcp__claude-in-chrome__*` for the
file-input step only. Proven 2026-10-13 (claude-in-chrome), text via Playwright 2026-10-14.

## 🧭 Playwright for text, claude-in-chrome for files only

- `mcp__playwright-chrome__*` drives David's Chrome, so it sees the logged-in WhatsApp session.
  `mcp__playwright-brave__*` is wrong twice: it opens its own tab, and WhatsApp never runs in Brave
- Playwright's `browser_file_upload` fails in extension mode (`DOM.setFileInputFiles: Not allowed`),
  so an attachment's file-input step is claude-in-chrome's `file_upload`. Nothing else is
- 2026-10-14: tanstack.link drove claude-in-chrome for a plain text message because this file
  routed every send there. David called that wrong. Text never needs claude-in-chrome
- Keep each claude-in-chrome `javascript_tool` call under 45s, or the CDP call times out

## ⚠️ One live session

- David uses WhatsApp in the **Brave app window**. Agents use WhatsApp Web in Chrome, so the
  two never fight over the single session. **Never open WhatsApp in Brave**
- WhatsApp Web keeps one active session. A tab in another browser shows "Use here"; a second
  tab in the same Chrome profile just loads the chats (2026-10-14)
- Any other open WhatsApp window (the Brave PWA, another Chrome tab) grabs it back, so David
  closes those first
- Taking the session from Brave stops the notifications that `teamup-mac-notify-watch` reads.
  Hand it back when done

## 👀 Show David the draft

Preview it in David's own chat before sending it to anyone else:

- Search for David. The row is `אבא אבא דוד זיסקינד (You)`, and the header reads `Message yourself`
- Check the `#main` header before sending, every time

## ✍️ Text

- `browser_navigate` to `https://web.whatsapp.com/`, `browser_find` the chat row, click it
- Type with `browser_type` and `slowly: true` (keystrokes). Without `slowly` it is `fill()`, which
  replaces the whole box; `execCommand('insertText')` doesn't take either
- One `browser_type` per line, `browser_press_key` `Shift+Enter` between lines (twice for a blank
  line). Plain Enter sends
- `*bold*` and `_italic_` render, typed literally
- `browser_take_screenshot` only writes under the cwd: pass a bare filename, then `mv` it to the
  scratchpad
- `browser_tabs close` your tab when done. The Chrome session stays logged in

## 🔗 Links

WhatsApp shows URLs raw and never a label, so `[text](url)` arrives as literal brackets
(2026-10-14, Shahar reply: David called it "shit"). Instead:

- Keep the prose link-free, then a blank line, then one `Label: url` line per link
- Short URLs only: a PR, a b44sync task, a short GitHub path. Never a long GitHub path with an anchor
- Two or three links at most; a manager gets the decision and the PR, not implementation details
- The first URL gets a preview card: close it (its X above the composer) before sending

The shape David approved (lead.static.0, 2026-10-13):

```
Yes, started. *cli only, happy path, first draft.* direction makes sense?

PR: https://github.com/base44/cli/pull/661
Task: https://b44sync.base44.app/rd-hub/tasks/BASE-51241
_agent: lead.static.0_
```

## 🎬 Video with a thumbnail (claude-in-chrome)

Load the `claude-in-chrome` skill: only its `file_upload` can set the file input. Send the video
as media, not as a link. **Wait for the chat pane to render before Attach**: while it's
still loading, the upload silently does nothing.

1. Patch `HTMLInputElement.prototype.click` so it skips file inputs. Clicking "Photos & videos"
   creates a file input (`accept image/*,video/mp4,…`) and `click()`s it, which opens the native
   picker. Give the input an `aria-label` so it can be found
2. Attach › "Photos & videos"
3. Find the file input, then `file_upload` the H.264 `.mp4`. The file must be in the session's
   scratchpad
4. Type the caption into the preview's caption box
5. Click "Send 1 selected"
6. Restore `prototype.click`

Result: an inline video with a thumbnail, with the caption under it.
