# WhatsApp

Send through WhatsApp Web in **Chrome**, with the `mcp__claude-in-chrome__*` tools (load the
`claude-in-chrome` skill first). First proven 2026-10-13.

## 🧭 Why claude-in-chrome, not Playwright

- `mcp__playwright-brave__*` can't see David's existing WhatsApp tab. It opens its own tab
- Its file upload fails with `DOM.setFileInputFiles: Not allowed`
- Keep each `javascript_tool` call under 45s, or the CDP call times out

## ⚠️ One live session

- David uses WhatsApp in the **Brave app window**. Agents use WhatsApp Web in Chrome, so the
  two never fight over the single session. **Never open WhatsApp in Brave**
- WhatsApp Web keeps one active session. A new tab shows "Use here"
- Any other open WhatsApp window (the Brave PWA, another Chrome tab) grabs it back, so David
  closes those first
- Taking the session from Brave stops the notifications that `teamup-mac-notify-watch` reads.
  Hand it back when done

## 👀 Show David the draft

Preview it in David's own chat before sending it to anyone else:

- Search for David. The row is `אבא אבא דוד זיסקינד (You)`, and the header reads `Message yourself`
- Check the `#main` header before sending, every time

## ✍️ Text

- Use computer `type` once per line, with `shift+Enter` between lines
- Playwright `fill()` replaces the whole box, and `execCommand('insertText')` doesn't take
- `*bold*` and `_italic_` render. Links show as raw URLs, and the first URL gets a preview card

## 🎬 Video with a thumbnail

Send it as media, not as a link. **Wait for the chat pane to render before Attach**: while it's
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
