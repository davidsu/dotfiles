# Global Instructions for All Projects

## Auto-Load Skills

### Coding Context

**CRITICAL REQUIREMENT**: Before writing or modifying code, you MUST load `/clean-code` if you haven't already loaded it in this conversation.

This ensures you follow clean code principles and coding standards automatically.

## NEVER Guess

**CRITICAL**: NEVER guess. If you don't know something — a file path, a function name, a behavior, a fact — either research it first (read the file, run the command, search the codebase) or say "I don't know." Ask the user to clarify if needed. Absolutely NEVER fabricate details, plausible-sounding answers, or fill in blanks with assumptions. Wrong information is worse than no information.

## Always Use Full Paths

When referencing a file, use its absolute path (e.g. `/Users/davidsu/projects/apper/app/api/user_repos_api.py:115`), not a bare filename (`user_repos_api.py:115`). This keeps cmd+click working in the terminal. Applies everywhere, prose answers included.

## Always Show Proof

**CRITICAL**: When reporting findings from external data — logs, metrics, dashboards, DB queries, web sources — every claim must carry a pointer the user can open themselves, captured while the evidence is in front of you:

- **Metrics / logs / dashboards** → the URL encoding the exact query and timeframe
- **Command / query results** → the command and its relevant output
- **Code** → `path/file.ext:line`
- **External facts** → the source URL

Evidence only you saw is not evidence. No pointer → mark the claim unverified. (The user can also demand proof after the fact via `/suss-proof`.)

### Cite sources with clickable links
A quote, or "X asked / said / answered", links to that comment's permalink,
This applies to everyday answers too, not only investigations. Any PR, issue, ticket,
comment, review, Slack message or doc you mention must be a clickable markdown link to the exact
item, so the user can check it in one click:

- **PR / issue / ticket** → `[#28299](https://github.com/…/pull/28299)`, `[BASE-66214](https://…/browse/BASE-66214)`, never a bare `#28299`
- **A quote, or "X asked / said / answered"** → link the words to the permalink of that exact message, wherever it lives: a GitHub comment (`…/pull/N#discussion_r…`, `#issuecomment-…`), a Slack message, an email, a doc comment. Never just the PR, channel or thread
- **A claim about what a thread concluded** → link the comment where it was concluded

If you don't have the URL, fetch it (e.g. `gh api …/comments`, the Slack permalink) before you send the answer. If you can't get it, say the reference is unlinked.

## Ask When Uncertain

If you're uncertain about requirements, ask for clarification BEFORE implementing. If an attempt fails and you still don't understand, STOP and ask - don't loop through guesses.

## Broken `suss-*` skills

The `suss-*` skills are David's own and meant to improve as they're used. If one breaks or misleads
you (a wrong step, a stale path, a rule that fights the task), don't quietly work around it. Tell
David in one line what broke and suggest spawning an agent in the skill's repo (`readlink` the
skill dir in `~/.claude/skills/`) to fix it with him. Don't fix it yourself mid-task, and don't
raise it for style nits.

## Commit signature

End every commit message with a last line `agent: <your handle>` (your session name), the same
signature as Slack posts. No other footers: no "Generated with Claude Code", no "Co-Authored-By".

## Agent answer header

**CRITICAL** Every reply opens with one header line. It tells David what the reply answers, so he
can scroll back and find his own last question among agent traffic.

**A prompt David typed into THIS terminal** gets the loud header, and only that:

**>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ANSWER <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<**

**Anything else** gets a quiet header naming what triggered the turn, never the loud one. This
includes David's words relayed by another agent ("From David via …"). When the trigger is a
message, the header is a markdown link to the line holding that message: cmd+click opens it in
nvim at that line, so David can read the question. Pad with `-` on both sides so the visible
line is 115 characters, the loud header's width. Never more: it must fit on one line.

- suss-teamup message, `[@sender:channel](file:///tmp/suss-teamup/{channel}/channel.tsv:{seq})`.
  The line number is the message's `#<seq>`. A teamup listener (`teamup wait`) finishing is a
  teamup message, not a task: link the message(s) it woke you for, one link each.
  ```
  ---------------------------------------- [@lead.12:task_links](file:///tmp/suss-teamup/task_links/channel.tsv:39) ----------------------------------------
  ```
- `Message from @handle` (direct peer message), `[@sender](file://{transcript}:{line})`: the line
  of your own transcript holding it. Find it with
  `t=$(ls ~/.claude/projects/*/"$CLAUDE_CODE_SESSION_ID".jsonl); echo "$t:$(rg -n --no-config '"role":"user","content":"Another Claude session sent a message' "$t" | tail -1 | cut -d: -f1)"`
  ```
  ---------------------------------------------- [@task-hub-improvement](file:///Users/davidsu/.claude/projects/{project}/{session-id}.jsonl:{line}) ----------------------------------------------
  ```
- Background task / subagent notification: `↪ task: {task name}`, padded the same way
- Cron / loop tick: `↪ loop: {what it checks}`, padded the same way

## Tools

Prefer tavily mcp to WebSearch tool whenever tavily is available

### Search & Optimization

- **Search Preference:** Never use `find | grep` or recursive `grep` in Bash.
- **Ripgrep:** Always use `rg` (ripgrep) for searching patterns — even inside Bash commands. Prefer the dedicated Grep/Glob tools when they fit.
- **File Listing:** Prefer `rg --files` over `find` for listing files (faster, respects .gitignore).
- **Efficiency:** Use `rg` flags like `--vimgrep` or `-C` for context.
- **Ignore Patterns:** Rely on `rg`'s default behavior of respecting `.gitignore` to avoid scanning `node_modules` or build artifacts.

# Apper

## claude.md

if pwd is worktree of ~/projects/apper then you must read ~/projects/apper/CLAUDE.local.md

## suss-tasks

every worktree of ~/projects/apper should handle its tasks in ~/projects/apper/suss-tasks, not in subdirectory of the worktree
