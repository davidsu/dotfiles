open
# Playwright MCP: logged-in browser, separate from mine

## Summary

Give Claude a Playwright-driven browser that has my full login state, but runs as its own instance instead of my everyday Chrome. Claude then won't compete with me for tabs and focus, and won't touch my windows.

## 🧭 Today

The `cyc` alias ([aliases.zsh](/zsh/sources/aliases.zsh#L38), documented in [README.md](/README.md?plain=1#L436-L439)) wires up three Playwright servers:

| Server                   | Logged in | Separate instance |
|--------------------------|-----------|-------------------|
| `playwright-chrome`      | ✅        | ❌ (extension)    |
| `playwright-chrome-anon` | ❌        | ✅ (`--isolated`) |
| `playwright-brave`       | ✅        | ❌ (extension)    |

## 🎯 Gap

No server is both logged in **and** a separate instance.

## 🔗 Touch points when implemented

- [aliases.zsh](/zsh/sources/aliases.zsh#L38): add the new server to `cyc`
- [README.md](/README.md?plain=1#L436-L439): document it
- [suss-browser SKILL.md](/claude/skills/suss-browser.ln/SKILL.md?plain=1#L15-L31): add it to the server table and say when to pick it

## 🪦 Abandoned (David, 2026-10-07)

"I don't like any of them": Playwright keeps using David's personal Chrome (extension mode). Options weighed:
- **Separate instance on a copy of the profile**: Chrome 136+ ignores the remote-debugging switches on the default data dir, so a second instance needs its own `--user-data-dir` ([Chrome blog](https://developer.chrome.com/blog/remote-debugging-port)); copied logins may not decrypt there, and the copy drifts as David gets logged out and back in.
- **Same profile, agent tabs in their own window**: extension mode has no such option ([Playwright docs](https://playwright.dev/mcp/configuration/browser-extension)); a theme can't color one window of a profile.
- **Second Chrome profile "Agents"** (`--extension --profile-dir-name=…`, own theme color): supported, but needs its own logins, which David re-does constantly.

---
**Created by**: claude-code-session (2026-10-06)
