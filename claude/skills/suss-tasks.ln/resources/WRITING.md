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
├── migrate-to-suss-tasks/          # directory with epic.md
│   ├── epic.md                     # describes this group of tasks
│   ├── create-skill.md             # task
│   ├── create-nvim-plugin.md       # task
│   └── remove-beads-wiring/        # sub-directory (nesting is fine)
│       ├── epic.md
│       ├── remove-hooks.md
│       └── remove-nvim-plugin.md
├── improve-statusline/
│   ├── epic.md
│   └── add-git-branch.md
└── fix-mru-crash.md                # standalone task (no directory)
```

**Rules:**

1. **Directories group tasks** — an `epic.md` inside describes the group
2. **Tasks are `.md` files** — the filename is the task name
3. **Standalone tasks** go directly under `suss-tasks/`
4. **Nesting is unlimited** — directories can contain directories
5. **Kebab-case** for all filenames and directories

## Creating Tasks

Just write the file. No CLI, no commands.

```bash
# Standalone task
Write suss-tasks/fix-mru-crash.md

# Task under an epic (create directory if needed)
mkdir -p suss-tasks/migrate-to-suss-tasks
Write suss-tasks/migrate-to-suss-tasks/create-skill.md
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

## File Path References

Use **git-root-relative paths** with line numbers:

```
config.ln/nvim/lua/beads/viewer.lua:142
config.ln/nvim/lua/beads/viewer.lua:330-335
```

**Rules:**

1. Git-root-relative — not filenames alone, not absolute paths
2. Verify path exists before writing
3. Verify line numbers are accurate
4. Keep path and line together as `path:line` — never split into separate columns

## Markdown Table Alignment

All tables MUST have columns padded to consistent widths:

```
| File              | Risk     | What Breaks                       |
|-------------------|----------|-----------------------------------|
| domains.ts        | CRITICAL | 3 URL functions produce undefined |
| AppDomains.js     | HIGH     | SlugEditor shows broken URL       |
```

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
