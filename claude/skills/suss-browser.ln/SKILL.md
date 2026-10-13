---
name: suss-browser
description: >
  Use the browser (run/test/interact with a web page). Invoked manually via
  /suss-browser. Picks the right tool (Playwright MCP vs claude-in-chrome)
  and the right browser (personal Chrome, anonymous Chrome, or Brave).
---

# suss-browser

Default to the Playwright MCP tools — load them in one ToolSearch call if
deferred. claude-in-chrome is weaker: it cannot click/scroll/manipulate
inside iframes.

Each Playwright MCP server name says which browser it drives:

| Tool namespace | Drives |
|----------------|--------|
| `mcp__playwright-chrome__*` | David's personal Chrome (logged in) |
| `mcp__playwright-chrome-anon__*` | anonymous Chrome (fresh in-memory profile) |
| `mcp__playwright-brave__*` | David's personal Brave |
| claude-in-chrome | David's personal Chrome |

Rules:

- **Prefer Chrome with the user profile unless explicitly asked otherwise.**
  Default to `mcp__playwright-chrome__*`; touch `mcp__playwright-brave__*`
  only when the task names Brave.
- Use `mcp__playwright-chrome-anon__*` when the task needs a logged-out /
  clean-profile browser (e.g. testing signup or incognito-like behavior).
- Use Playwright over claude-in-chrome for everything, except file uploads.

File uploads (e.g. attaching to a GitHub comment) need `mcp__claude-in-chrome__file_upload`.
Playwright's `browser_file_upload` only reads files under the project dir (not the scratchpad),
and in extension mode setting them fails anyway (`DOM.setFileInputFiles: Not allowed`).

- A hidden input (GitHub's `#fc-new_comment_field`) won't show up in `find`: un-hide it via
  `javascript_tool` and give it an `aria-label`, then `find` it and `file_upload` to it.
- GitHub: poll the textarea's value for the `github.com/user-attachments/assets/...` URL.
  Clear the textarea afterwards unless you're meant to post.
- Video: upload H.264 `.mp4` (`avconvert --preset Preset1920x1080 -s in.mov -o out.mp4`).
  A `.mov` was rejected (`is-bad-file`).

Tabs (extension mode, `playwright-chrome`/`playwright-brave`):

- Each connection starts in a `[Welcome]` tab. Make your first call `browser_navigate` so it
  becomes your tab; `browser_tabs new` first leaves it behind.
- Close tabs with `browser_tabs close`. `browser_close` leaves the tab open and drops the
  connection, so the next call opens another `[Welcome]`.
- Cleanup: don't leave tabs behind by accident. Keeping one open is fine with a reason.
- `scripts/close-ghost-tabs` closes `[Welcome]` tabs of dead sessions (runs on SessionEnd).
