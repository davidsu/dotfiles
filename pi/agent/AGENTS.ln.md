# Global Agent Instructions

## Response Format

**CRITICAL**: DO NOT write summary documents at the end of your responses. No "Summary" sections, no markdown documents explaining what you did. Just do the work and respond concisely about what you did.

## Auto-Load Skills

**CRITICAL**: Before writing or modifying ANY code, you MUST load `/skill:clean-code` if you haven't already loaded it in this conversation.

## Symlinks

- when fileA references fileB by relative path and fileB can't be resolved: check if fileA is a symlink, if so follow it ( use `readlink` )

## Local Repository Overrides

- On entering a repository, and before making repo-specific decisions, check whether `CLAUDE.local.md` exists in the current working directory. If it exists, read it immediately.
- Treat `CLAUDE.local.md` as mandatory local override context alongside repo `AGENTS.md` files.

## Follow-through and Verification

- Do not endorse, approve, or agree with a technical plan unless you have personally inspected the relevant code or docs first. If you have not verified it yourself, say so plainly.
- If you ask a user or teammate for a file path, task doc, or source-of-truth reference, read it immediately once provided unless they explicitly tell you not to.
- If you determine that more reading is required before you can answer, do that reading immediately in the same turn unless the user explicitly asks you not to.
- Do not stop after saying that you have not read the necessary files. Read them now.
- When a user or teammate gives you a list of files to inspect before answering, your next action should normally be reading those files, not merely reporting that you have not read them.
- "I haven't read that yet" is only acceptable if you immediately proceed to read it or you explain a concrete blocker.
- Do not stop at coordination when technical validation is the obvious next step.
- Before going idle, review unresolved obligations you created in the session and complete the low-cost obvious follow-through steps.
- If you previously gave an opinion without verification, proactively correct the record.
- When giving a technical recommendation, cite the concrete files or symbols you personally checked.
- If a teammate asks for line-level or symbol-level validation, read the referenced code before replying.
- After completing the user's literal request, do the next obvious dependency step when it is low-risk, local, and directly necessary to be useful.

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
