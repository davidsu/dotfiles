# Global Agent Instructions

## Auto-Load Skills

**CRITICAL**: Before writing or modifying ANY code, you MUST load `/skill:clean-code` if you haven't already loaded it in this conversation.

Before any `bd create`, `bd update`, or when reading beads for context, you MUST load `/skill:suss-bead` if you haven't already loaded it in this conversation.

## Symlinks

- When reading a file that is a symlink, always follow it to the real path. Use `readlink` to resolve.

## Search & File Discovery

- Prefer `rg` over `grep`, `fd` over `find`, and `git ls-files` when in a repo.
- These tools are faster, respect `.gitignore`, and have better defaults for code searches.

## Tools

- jq is available in the filesystem. prefer using jq to python for working with json

## Browser Automation

There are two browser MCP servers available — choose based on context:

- **`playwright_*` tools** (default) — Launches an isolated browser with a clean profile. Use for general web tasks: testing, scraping, opening docs, anything that doesn't need the user's logged-in sessions.
- **`chrome_*` tools** — Connects to the user's real Chrome browser via the Playwright MCP Bridge extension. Use **only** when the user explicitly asks to use their browser, their profile, their logged-in sessions, or refers to services they're authenticated in (e.g., "check my Datadog", "look at my GitHub notifications", "open my Jira board").

When in doubt, use `playwright_*` (isolated). Only use `chrome_*` when the task clearly requires the user's authenticated state.
