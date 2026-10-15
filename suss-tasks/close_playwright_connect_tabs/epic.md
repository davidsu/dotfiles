ready
# 🧹 Close leftover Playwright "Welcome" tabs in Chrome and Brave

## Summary

Every Claude session that touches `playwright-chrome` or `playwright-brave` leaves a "Welcome" tab (the extension's `connect.html`), and the extension never closes it. Proposal: a cleanup script that closes only the tabs whose relay is dead, run from the `SessionEnd` hook and exposed in `/suss-browser`.

## 🔍 Why the tabs stay (Playwright Extension 0.4.0, `@playwright/mcp` 0.0.78)

- **Each session opens one.** On first use, the MCP server spawns the browser with `chrome-extension://…/connect.html?mcpRelayUrl=ws://[::1]:PORT/extension/<uuid>&token=…` (`_openConnectPageInBrowser` in `@playwright/mcp/node_modules/playwright-core/lib/coreBundle.js`, ~line 72009).
- **The Welcome tab is the connected tab.** With a valid token, `connect.js` calls `connectToTab` with no tab, so the background uses `sender.tab`, i.e. the connect page itself (`message.tab ?? sender.tab` in `lib/background.mjs` `_connectTab`). It only removes the connect page when a *different* tab was picked, which never happens with the token.
- **Nothing closes it later.** When the connection drops, `_onConnectionClose` only *ungroups* the tabs, and `cleanupStalePlaywrightGroups` (runs at extension start) only ungroups too. There is no `chrome.tabs.remove` on disconnect.
- **Connections live as long as the session.** Each `cyc` session runs two `playwright-mcp --extension` processes (Chrome + Brave). On 2026-10-12 there were 13 sessions alive, one dating from Oct 5, so the coloured groups in the screenshots are mostly live sessions, not dead ones.

Extension source read at `~/Library/Application Support/Google/Chrome/Default/Extensions/mmlmfjhmonkocbjadbfplnigmagldckm/0.4.0_0/lib/`.

### 🧪 Live vs dead check (2026-10-12 20:40)

Reading tab URLs with `osascript`, then `lsof -iTCP:PORT -sTCP:LISTEN` on each relay port:

| Browser | Live relays         | Dead relays         |
|---------|---------------------|---------------------|
| Chrome  | 49796, 50117        | none                |
| Brave   | 51823, 57632, 62107 | 64967, 58010, 58511 |

So "relay port no longer listening" safely tells a dead tab from a live one.

## 🧪 Reproduced (2026-10-12, this session, `playwright-chrome`)

Tab URLs were read with `osascript` after each step.

| First call on a fresh connection | Welcome tab left?                                  |
|----------------------------------|----------------------------------------------------|
| `browser_navigate`               | ❌ the connect tab itself is navigated (reused)    |
| `browser_tabs new`               | ✅ connect page stays as tab 0 `[Welcome]`         |

- 🐛 **Ghost #1, Welcome tab:** an agent whose first call opens a new tab (`browser_tabs new`; likely also `context.newPage()` in `browser_run_code_unsafe`, untested) keeps the connect page as an extra tab. Playwright *does* list it (`browser_tabs list` shows `0: [Welcome](chrome-extension://…)`), and `browser_tabs close` index 0 really removes it.
- 🐛 **Ghost #2, orphaned real tabs:** `browser_close` answers "No open tabs" but the Chrome tab stays open; the connection drops, the next call opens a new relay (new port, new connect tab), and the old relay port keeps listening. So the dead-port check below can't catch these.
- ✅ `browser_tabs close` (by index) removes the Chrome tab for real.

### 🗣️ What the work agents do (from their runbooks, not observed)

- GitHub video upload: `browser_run_code_unsafe` opens the PR with `context.newPage()` and some scripts never close that page. This matches Ghost #1's mechanism (new page instead of navigating the connect tab).
- Login + `storageState` export in playwright-chrome and playwright-brave, then the agent closes its tab. The connect page isn't closed, so it stays.
- Owners are put to sleep with `teamup-sleep` (iTerm tab closed) while their MCP is still connected. Their `lead_runbook.md` sweep rule says to *leave* `connect.html` tabs because they belong to live agents.

## 💡 Proposal

0. **Agent rule in `/suss-browser`** (fixes the cause): the first call on a connection is `browser_navigate`, never `browser_tabs new`. Never `browser_close`. When done, `browser_tabs list` and `browser_tabs close` every tab you opened, `[Welcome]` included.

1. **`playwright-tab-cleanup` script** (`bin/`): for Chrome and Brave, list tabs with `osascript`, pick `connect.html?mcpRelayUrl=` tabs, and close the ones whose port isn't listening. Live sessions are left alone. Also an option to close the dead session's leftover `about:blank` tabs (unverified: how to tell them apart from David's).
2. **Run it automatically** from the existing `SessionEnd` hook in `~/.claude/settings.json`, backgrounded with a short delay so the session's MCP processes have exited first (unverified: whether MCP children are gone by the time `SessionEnd` fires).
3. **Mention it in `/suss-browser`** as the manual fallback.
4. **Optional upstream fix:** ask `microsoft/playwright-mcp` to `chrome.tabs.remove` the connect page on disconnect (not checked whether an issue already exists).

### ❓ Open questions

- Should closing a **live** session's Welcome tab be supported? It's the attached tab; unverified whether removing it drops the agent's connection (`_hasEverAttached && attachedTabs.size === 0` closes the connection).
- Does `browser_close` end the extension connection? Its handler only does `setClose()`; unverified whether the relay disconnects.

## 🔗 Touch points

- [aliases.zsh](https://github.com/davidsu/dotfiles/blob/6428fc122cf4f31168d2792c883e951ce3ab2776/zsh/sources/aliases.zsh#L38): `cyc` defines the three Playwright servers
- [suss-browser SKILL.md](https://github.com/davidsu/dotfiles/blob/6428fc122cf4f31168d2792c883e951ce3ab2776/claude/skills/suss-browser.ln/SKILL.md): document the cleanup
- `~/.claude/settings.json`: `SessionEnd` hook

abandoned/playwright_logged_in_separate_browser.md -> why Playwright still drives David's own Chrome/Brave

## ✅ Done (2026-10-13)

- `/suss-browser` gained 4 tab rules (navigate first, `browser_tabs close`, no accidental leftovers, the script).
- `claude/skills/suss-browser.ln/scripts/close-ghost-tabs` added: first run closed 7 dead-relay Welcome tabs and kept 4 live ones.
- `~/.claude/settings.json` SessionEnd runs it backgrounded after 5s (file not in dotfiles).
- Upstream fix (option 4) not pursued.

---
**Created by**: claude-code-session (2026-10-12)
**Updated by**: playwright.ghost.tabs (2026-10-12)
