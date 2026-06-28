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

Line 1 is the status — nothing else on that line:

```
open
# Task title here

## Summary
What this task is about...
```

### Valid Statuses

| Status        | Meaning                          |
|---------------|----------------------------------|
| `open`        | Ready to work on                 |
| `in_progress` | Currently being worked on        |
| `blocked`     | Waiting on something else        |
| `closed`      | Done                             |

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

Tasks live under `suss-tasks/` at the project root. Epics are directories. Tasks are files.

```
suss-tasks/
├── migrate_to_suss_tasks/          # directory with epic.md
│   ├── epic.md                     # describes this group of tasks
│   ├── create_skill.md             # task
│   ├── create_nvim_plugin.md       # task
│   └── remove_old_task_wiring/     # sub-directory (nesting is fine)
│       ├── epic.md
│       ├── remove_hooks.md
│       └── remove_nvim_plugin.md
├── improve_statusline/
│   ├── epic.md
│   └── add_git_branch.md
└── fix_mru_crash.md                # standalone task (no directory)
```

**Rules:**

1. **Directories group tasks** — an `epic.md` inside describes the group
2. **Tasks are `.md` files** — the filename is the task name
3. **Standalone tasks** go directly under `suss-tasks/`
4. **Nesting is unlimited** — directories can contain directories
5. **`snake_case` or `camelCase`** for filenames and directories — never kebab-case

## Creating Tasks

Just write the file. No CLI, no commands.

```bash
# Standalone task
Write suss-tasks/fix_mru_crash.md

# Task under an epic (create directory if needed)
mkdir -p suss-tasks/migrate_to_suss_tasks
Write suss-tasks/migrate_to_suss_tasks/create_skill.md
```

**When creating multiple tasks**, create them in parallel — they're just files.

## Updating Status

Edit line 1 of the file. That's it.

```bash
# Mark as in-progress: change line 1 from "open" to "in_progress"
Edit suss-tasks/epic/task.md  # old: "open" → new: "in_progress"
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
suss-tasks/epic/other-task.md#section-heading -> why this is relevant
```

### Example

```markdown
### Frontend — 8 Unguarded References

Audit found 8 `.slug` refs across 4 files.

suss-tasks/audit-slug-refs/fe-audit.md#frontend--8-real-risks -> detailed file list
suss-tasks/audit-slug-refs/backend-check.md#runtime-store -> confirms no backend changes
```

**Place references after the content they support** — never in a footer section.

## Code References — Root-Relative Markdown Links

Reference code with **GitHub-style markdown links whose path starts with `/`**. The
leading `/` makes GitHub resolve the link from the **repository root**, so the link
renders as a clickable, line-highlighted link for colleagues on GitHub **and** keeps
working when the task file is moved (e.g. into `suss-tasks/done/`).

```markdown
[reduceSandboxSlot](/frontend/.../sandbox.reducer.ts#L90)          single line
[recomputeStatus](/frontend/.../sandbox.reducer.ts#L10-L26)        line range
[validate_final_state](/backend/.../background_validation.py#L86)  any source file
```

In editor (`gd` on the link) this opens the file, highlights the range, and centers
the viewport — the same link works in Neovim and on GitHub. To read a doc in the
browser, use `:TaskPreview` (not `:MarkdownPreview`): it previews a copy with these
root-relative links rewritten to local `file://` paths, so they open instead of 404ing.

**Rules:**

1. **Always start the path with `/`** — repo-root-relative, so it survives moving the `.md`
2. **Line fragment is `#L<line>` or `#L<start>-L<end>`** (capital `L`, dash between)
3. **No column anchors** — GitHub does not support `#L31C5`; line/range only
4. **Linking to lines in another `.md`** needs `?plain=1`: `[x](/suss-tasks/foo.md?plain=1#L14)`
5. **Multiple discrete lines** = multiple links (e.g. `#L31` and `#L71`), not `#L31,L71`
6. Verify the path exists and the line numbers are accurate before writing

### Reference-style links — for table cells (keep the reading area narrow)

Inline links are fine in prose. But inside **table cells** a full path is 200+ chars, which
blows the column out and makes the table unreadable (see "Markdown Table Alignment"). Use a
**reference-style link** instead: a short token in the cell, with the long path collected in a
refs block at the **bottom of the file**.

```markdown
| #  | Primitive                       | What it does                          |
|----|---------------------------------|---------------------------------------|
| P1 | data-driven URL recompute       | [reduceSandboxSlot][p1] recomputes url |

<!-- code refs -->
[p1]: /frontend/.../appPreviewStore/sandbox.reducer.ts#L90
```

`gd` on `[reduceSandboxSlot][p1]` (cursor on either bracket) resolves the `[p1]:` definition and
jumps to the file — same as an inline link. GitHub renders it as a normal clickable link, and the
`[p1]: …` definition lines are invisible in the rendered view.

**Rules:**

1. **Cell holds a short token** — `[human label][key]`; the `key` is a terse slug (`p1`, `p2b`, `fe_audit`)
2. **All definitions go in ONE block at the very bottom**, under a `<!-- code refs -->` comment, after the authorship footer
3. **Definition format**: `[key]: /repo-root-relative-path#L<line>` — same path rules as inline links above
4. **Keys are unique, lowercase, and use `_` not `-` as the separator** (`r_wtfa`, `g_sync_status`) — Vim's `iskeyword` excludes `-`, so `*`/`#`/`gd`-style word motions treat a `-`-joined token as several words; `_` keeps the whole key one word so `*` on it jumps between its uses
5. Reuse one key if the same location is cited from multiple cells
5. Verify each `[key]` has exactly one matching `[key]: …` definition

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
