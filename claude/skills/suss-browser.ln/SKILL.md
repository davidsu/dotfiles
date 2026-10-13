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
- Use Playwright over claude-in-chrome for everything.

Tabs (extension mode, `playwright-chrome`/`playwright-brave`):

- Each connection starts in a `[Welcome]` tab. Make your first call `browser_navigate` so it
  becomes your tab; `browser_tabs new` first leaves it behind.
- Close tabs with `browser_tabs close`. `browser_close` leaves the tab open and drops the
  connection, so the next call opens another `[Welcome]`.
- Cleanup: don't leave tabs behind by accident. Keeping one open is fine with a reason.
- `scripts/close-ghost-tabs` closes `[Welcome]` tabs of dead sessions (runs on SessionEnd).
