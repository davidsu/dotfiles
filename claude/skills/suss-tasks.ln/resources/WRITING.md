# Task Writing Conventions

## NEVER GUESS — Accuracy is Mandatory

Everything written into a task MUST be correct and verified. Tasks are persistent project memory — wrong information pollutes future sessions and misleads other agents.

**Rules:**

1. **Do NOT guess** file paths, line numbers, function names, or any factual claim
2. **Research first** — read the code, run the command, check the file before writing claims
3. **Ask the user** if you cannot verify something
4. **Omit rather than guess** — fewer verified facts beats fabricated details

## File Format

### Status Shebang

Line 1 is the status — nothing else on that line. Line 2 is the title, starting with the
effort's emoji ([ORGANIZATION.md](ORGANIZATION.md)):

```
open
# 🔒 Task title here

## Summary
What this task is about...
```

### Valid Statuses

| Status        | Meaning                          |
|---------------|----------------------------------|
| `open`        | Not started yet                  |
| `in_progress` | Currently being worked on        |
| `blocked`     | Waiting on something else        |
| `ready`       | Work done, waiting on review     |
| `closed`      | Done                             |

The task owner sets `ready` once only review remains.

### Minimal Task

The smallest valid task:

```
open
# Fix the broken symlink handler
```

### Full Task

```
open
# Fix the broken symlink handler

## Summary

The symlink handler crashes when the target path contains spaces. Need to quote paths in the shell command.

## Details

`installation/link.sh:42` builds the `ln -s` command with unquoted variables.
Reproduces on any path with spaces — e.g., `~/Library/Application Support/`.

## Notes

- 2026-03-11: Confirmed affects macOS only, Linux `ln` handles it differently
```

## Directory Structure

Tasks live under `suss-tasks/` at the project root, in efforts (words: SKILL.md → Vocabulary). An effort is a directory; its epic, tasks, memos and assets are files inside it. There are no standalone task files.

```
suss-tasks/
├── migrate_to_suss_tasks/          # effort
│   ├── epic.md                     # the epic: describes the effort
│   ├── create_skill.md             # task
│   ├── create_nvim_plugin.md       # task
│   └── remove_old_task_wiring/     # sub-effort (nesting is fine)
│       ├── epic.md
│       ├── remove_hooks.md
│       └── remove_nvim_plugin.md
├── improve_statusline/
│   ├── epic.md
│   └── add_git_branch.md
└── fix_mru_crash/                  # even a single task gets its own effort
    ├── epic.md
    └── quote_link_paths.md
```

**Rules:**

1. **Every task lives in an effort, as its own file** — never a bare `.md` file directly under `suss-tasks/`, and never the epic: a one-off is an effort with an epic and one task file (David, 2026-10-18)
2. **Tasks are `.md` files** — the filename is the task name
3. **Nesting is unlimited** — efforts can contain sub-efforts
4. **`snake_case` or `camelCase`** for filenames and directories — never kebab-case

## Creating Tasks

Just write the file. No CLI, no commands.

```bash
# One-off task — still an effort: the epic plus one task file
mkdir -p suss-tasks/fix_mru_crash
Write suss-tasks/fix_mru_crash/epic.md
Write suss-tasks/fix_mru_crash/quote_link_paths.md

# Task in an existing effort
mkdir -p suss-tasks/migrate_to_suss_tasks
Write suss-tasks/migrate_to_suss_tasks/create_skill.md
```

**When creating multiple tasks**, create them in parallel — they're just files.

## Updating Status

Edit line 1 of the file. That's it.

```bash
# Mark as in-progress: change line 1 from "open" to "in_progress"
Edit suss-tasks/effort/task.md  # old: "open" → new: "in_progress"
```

## Closing Tasks

Set status to `closed`. Optionally add a closing note:

```
closed
# Fix the broken symlink handler

## Summary
...

## Closing Note

Fixed in commit abc123. Quoted all path variables in `link.sh`.
```

## Summary Section

Every task with more than just a title SHOULD have a `## Summary` — 1-3 sentences explaining purpose and key outcome. This enables skimming without reading full descriptions.

**Rules:**

1. Should be the first `##` section
2. 1-3 sentences max — what and why
3. Plain text only — no code blocks or tables in the summary

## Inline Source Attribution

When a task references findings from other tasks, cite them inline so readers can navigate to the source:

```
suss-tasks/effort/other-task.md#section-heading -> why this is relevant
```

### Example

```markdown
### Frontend — 8 Unguarded References

Audit found 8 `.slug` refs across 4 files.

suss-tasks/audit-slug-refs/fe-audit.md#frontend--8-real-risks -> detailed file list
suss-tasks/audit-slug-refs/backend-check.md#runtime-store -> confirms no backend changes
```

**Place references after the content they support** — never in a footer section.

## Code References — GitHub Permalinks

Task files live outside the repo they describe, and the code may sit in any worktree or
branch. So every reference to code is a **full GitHub URL pinned to a pushed commit sha**:
it opens from any preview, on GitHub, and wherever the task is synced, and keeps pointing
at the lines you read even after the branch moves or is deleted.

```markdown
[reduceSandboxSlot](https://github.com/<owner>/<repo>/blob/<sha>/frontend/.../sandbox.reducer.ts#L90)
[recomputeStatus](https://github.com/<owner>/<repo>/blob/<sha>/frontend/.../sandbox.reducer.ts#L10-L26)
[#1234](https://github.com/<owner>/<repo>/pull/1234)
```

**Rules:**

1. **Pin to the sha you verified the lines at** — the PR head for code a PR changes, the default branch's HEAD otherwise; it must be pushed (an unpushed commit 404s), never a branch name (deleted on merge)
2. **Moving a link to a newer sha re-dates the claim** — re-read the lines at that sha first; they drift, and the claim may no longer hold. Old text with no recorded sha: re-read at today's default-branch HEAD and pin to that
3. **A PR, issue or commit is always a link** — `[#1234](…/pull/1234)`, never a bare `#1234`
4. **A file is never a bare path** — not `` `src/foo.ts` ``, not `` `foo.ts` ``; link it. Backticks are for identifiers (`useFoo`, `mainOnly`)
5. **Short link text** — `[foo.ts](…)` or `[#1234](…)`, never the raw URL as text
6. **Line fragment is `#L<line>` or `#L<start>-L<end>`** (capital `L`, dash between); no column anchors (`#L31C5`)
7. **Multiple discrete lines** = multiple links (e.g. `#L31` and `#L71`), not `#L31,L71`
8. **Linking to lines in another task `.md`** needs `?plain=1`: `[x](sibling.md?plain=1#L14)`
9. Verify the path exists at that sha and the line numbers are accurate before writing
10. **A path on this machine** (`~/…`, `/Users/…`, `/tmp/…`) has no URL: write it absolute, in backticks, never relative (`compose.mjs` reads as a repo file)

## PR Line

A task that has a PR, open, merged or closed, carries a `**PR**:` line holding the PR's full
url as a link. Most tasks exist before their PR: the agent who opens the PR adds the line the
moment the PR exists, and keeps it current on a re-land or a replacement PR, the old PR moving
into prose. One line per task; a stacked or follow-up PR is chained in it. Linking the PR
elsewhere (a table, a Closing Note) does not replace the line.

```markdown
**PR**: [#1234](https://github.com/<owner>/<repo>/pull/1234) (stacks on [#1230](https://github.com/<owner>/<repo>/pull/1230))
```

**Rules:**

1. **Place**: the metadata block right above the `---` authorship footer, next to `**Owner**`, `**List**`, `**Slack**`
2. **Shape**: `**PR**: [#N](https://github.com/<owner>/<repo>/pull/N)`, then any note in parentheses; `suss-sync-tasks` `push` refuses a `**PR**:` line with no pull url
3. **Written by the agent who opens the PR**, the moment it opens; a PR opened later for an already-written task gets the line added then
4. **Updated on re-land**: a replacement PR takes the line, the superseded one is mentioned in prose

### Reference-style links — for table cells (keep the reading area narrow)

Inline links are fine in prose. But inside **table cells** a full URL is 100+ chars, which
blows the column out and makes the table unreadable (see "Markdown Table Alignment"). Use a
**reference-style link** instead: a short token in the cell, with the long path collected in a
refs block at the **bottom of the file**.

```markdown
| #  | Primitive                       | What it does                          |
|----|---------------------------------|---------------------------------------|
| P1 | data-driven URL recompute       | [reduceSandboxSlot][p1] recomputes url |

<!-- code refs -->
[p1]: https://github.com/<owner>/<repo>/blob/<sha>/frontend/.../sandbox.reducer.ts#L90
```

`gd` on `[reduceSandboxSlot][p1]` (cursor on either bracket) resolves the `[p1]:` definition and
opens the target — same as an inline link. GitHub renders it as a normal clickable link, and the
`[p1]: …` definition lines are invisible in the rendered view.

**Rules:**

1. **Cell holds a short token** — `[human label][key]`; the `key` is a terse slug (`p1`, `p2b`, `fe_audit`)
2. **All definitions go in ONE block, the last one in the file**, under a `<!-- code refs -->` comment, after the authorship footer. The sync tool's tracking line may land before or after it; leave it where it is
3. **Definition format**: `[key]: <permalink>` — same rules as inline links above
4. **Keys are unique, lowercase, and use `_` not `-` as the separator** (`r_wtfa`, `g_sync_status`) — Vim's `iskeyword` excludes `-`, so `*`/`#`/`gd`-style word motions treat a `-`-joined token as several words; `_` keeps the whole key one word so `*` on it jumps between its uses
5. Reuse one key if the same location is cited from multiple cells
5. Verify each `[key]` has exactly one matching `[key]: …` definition

## Videos

A video is a **link to a public URL**, never a local path or a file committed to the repo: a
URL is the one form that opens in the raw file, every markdown preview, GitHub and the task
board alike.

```markdown
[![▶ tap shows the toast](https://media.example.com/…/tap_toast_poster.png)](https://media.example.com/…/tap_toast.mp4)
```

**Rules:**

1. **Get the URL from the task sync tool** — for b44sync, `suss-sync-tasks` `attach <task.md> <video>` uploads it, attaches it to the board task and prints the line to paste
2. **The URL is world-readable** — record only test or staff apps; never customer data, tokens or real emails
3. **WebM or MP4** — the board lists videos as attachments that open in a browser tab, which plays both; no conversion needed
4. **Link text says what the video shows**, starting with `▶`
5. **Next to the claim it proves** — like any reference, not in a footer
6. **Always a thumbnail** — a bare `▶` link reads as text and nobody notices it is a video. `attach` a poster PNG and wrap the link in it: `[![▶ what it shows](poster_url)](video_url)` renders a clickable thumbnail on the board and on GitHub
7. **The poster shows the proof** — the frame where the claim is visible (`ffmpeg -ss 5 -i v.webm -frames:v 1 poster.png`), left as is: the board draws its own play button, so a drawn one shows twice

## Markdown Table Alignment

All markdown tables MUST have columns padded to consistent widths. This is critical for readability in neovim and terminal viewers that render markdown as-is.

### Bad (unaligned)

```
| Caller | File:Line | Status |
|--------|-----------|--------|
| Password reset | runtime_api.py:714 | THEORETICAL |
| WhatsApp redirect | app_agents/runtime_api.py:246 | THEORETICAL |
```

### Good (aligned)

```
| Caller            | File:Line                     | Status      |
|-------------------|-------------------------------|-------------|
| Password reset    | runtime_api.py:714            | THEORETICAL |
| WhatsApp redirect | app_agents/runtime_api.py:246 | THEORETICAL |
```

### Rules

1. **Pad every cell** to the width of the longest value in that column
2. **Pad the separator row** (`|---|`) to match column widths
3. **Use trailing spaces** to align the closing `|` on every row
4. **Left-align** all content (no centering with `:---:`)
5. **Keep header text short** — if a header is longer than most values, consider abbreviating
6. **Keep cells short** — never put a full markdown link (200+ chars) in a cell. Use a
   reference-style token instead (see "Reference-style links — for table cells"). A column whose
   longest value is a code reference should hold a short `[label][key]` token, not the path.

### How to Apply

Don't eyeball it — compute the widths:

1. Collect all rows first (header + body)
2. Calculate the max width per column across every row, **counting characters** (an emoji counts
   as 1, even though it renders 2 columns wide — don't try to compensate; char-count keeps the
   markdown source consistent and is what tooling expects)
3. Pad each cell with trailing spaces to that column's max width
4. Build the separator row with dashes filling each column's width
5. Then write the final table

Cells stay narrow because long code paths live in the bottom refs block, not in the cells — so no
column should ever be more than ~40 chars wide. If one is, you almost certainly have a raw link in
a cell that belongs in a reference.

## Writing Style

Make tasks pleasurable to read:

- **Emojis as visual anchors** — one per header or key item, not every bullet
- **Short paragraphs** — 2-3 sentences max
- **Bullet lists** over run-on sentences
- **Tables** for structured comparisons
- **Headers liberally** — `###` subsections aid navigation

```markdown
## 🔍 Findings

### ✅ Runtime Store — No Changes

Handles null slugs by design.

### ⚠️ Frontend — 8 Unguarded Refs

| File          | Risk     | What Breaks                       |
|---------------|----------|-----------------------------------|
| domains.ts    | CRITICAL | 3 URL functions produce undefined |
```

## Authorship Footer

Every task MUST include authorship tracking at the bottom:

```markdown
---
**Created by**: claude-code-session (2026-03-11)
**Updated by**: architect (2026-03-11), domain-researcher (2026-03-12)
```

**Rules:**

1. **Always at the bottom** — after all content, preceded by `---`
2. **Created by** — agent/session name + date (YYYY-MM-DD)
3. **Updated by** — comma-separated list, each with name + date
4. **On create**: add `Created by` line
5. **On update**: append to `Updated by` line (don't remove previous entries)
6. **Naming**: use agent name if running as agent, otherwise `claude-code-session`

## Mermaid Diagrams

Use mermaid diagrams when they clarify flows, dependencies, or decision trees. Don't use when a bullet list or table works just as well.

### MUST: Validate Before Writing

**Every mermaid block MUST be validated before writing.** Use the validation script:

```bash
# Validate all mermaid blocks in a file
~/.claude/skills/suss-tasks/scripts/validate-mermaid /tmp/task-desc.md

# Validate a single diagram
~/.claude/skills/suss-tasks/scripts/validate-mermaid --string 'graph LR; A --> B'
```

### Common Pitfalls

**Colons in labels** — the #1 cause of mermaid failures:

```
BAD:  A --> B: AppContext.js:28 stores raw appId
GOOD: A --> B: AppContext.js line 28 stores raw appId
```

**Keep labels to plain English.** Move file paths, code snippets, and URLs into tables or bullets outside the diagram.
