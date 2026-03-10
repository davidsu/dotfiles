# Global Agent Instructions

## Response Format

**CRITICAL**: DO NOT write summary documents at the end of your responses. No "Summary" sections, no markdown documents explaining what you did. Just do the work and respond concisely about what you did.

## Auto-Load Skills

**CRITICAL**: Before writing or modifying ANY code, you MUST load `/skill:clean-code` if you haven't already loaded it in this conversation.

Before any `bd create`, `bd update`, or when reading beads for context, you MUST load `/skill:suss-bead` if you haven't already loaded it in this conversation.

## Symlinks

- when fileA references fileB by relative path and fileB can't be resolved: check if fileA is a symlink, if so follow it ( use `readlink` )

## Search & File Discovery

- Prefer `rg` over `grep`, `fd` over `find`, and `git ls-files` when in a repo.
- These tools are faster, respect `.gitignore`, and have better defaults for code searches.

## Tools

- jq is available in the filesystem. prefer using jq to python for working with json

## Environment Variables for Interactive Commands

- **Git rebase**: Always set `GIT_EDITOR=true` when running `git rebase --continue` to avoid getting stuck in an interactive editor
  ```bash
  GIT_EDITOR=true git rebase --continue
  ```

- **Man pages**: Always set `MANPAGER=cat` when reading man pages to avoid interactive pager issues
  ```bash
  MANPAGER=cat man <command>
  ```

## GitHub Operations

- Prefer `gh` CLI for GitHub operations (PRs, issues, repos, etc.) over direct API calls or web scraping
- For discussions: use `gh` extensions or provide manual steps if interactive input required

## Browser Automation

There are two browser MCP servers available — choose based on context:

- **`playwright_*` tools** (default) — Launches an isolated browser with a clean profile. Use for general web tasks: testing, scraping, opening docs, anything that doesn't need the user's logged-in sessions.
- **`chrome_*` tools** — Connects to the user's real Chrome browser via the Playwright MCP Bridge extension. Use **only** when the user explicitly asks to use their browser, their profile, their logged-in sessions, or refers to services they're authenticated in (e.g., "check my Datadog", "look at my GitHub notifications", "open my Jira board").

When in doubt, use `playwright_*` (isolated). Only use `chrome_*` when the task clearly requires the user's authenticated state.
