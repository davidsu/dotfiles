---
name: suss-browser
description: >
  Use the browser (run/test/interact with a web page). Invoked manually via
  /suss-browser. Picks the right tool: Playwright MCP vs claude-in-chrome,
  depending on the session launch mode (cyc vs cyp).
---

# suss-browser

Default to the Playwright MCP tools (`mcp__playwright__*`) — load them in one
ToolSearch call if deferred. claude-in-chrome is weaker: it cannot
click/scroll/manipulate inside iframes.

Which browser each tool drives depends on how the session was launched
(check with `pgrep -fl playwright`):

| Launch | Playwright process | Playwright drives | Personal Chrome via |
|--------|--------------------|-------------------|---------------------|
| `cyc`  | `playwright-mcp --extension` | David's personal Chrome | Playwright |
| `cyp`  | `mcp-server-playwright` | isolated browser | claude-in-chrome |

Rule: use Playwright for everything, except under `cyp` when the task needs
David's logged-in personal Chrome — then use claude-in-chrome.
