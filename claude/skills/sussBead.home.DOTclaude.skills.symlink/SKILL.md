---
name: sussBead
description: >
  Bead reading and writing conventions. Load before any bd create, bd update,
  or when reading beads for context. Covers ID naming, inline source attribution
  with section-slug navigation, parent traversal, and contradiction escalation.
---

# Bead Conventions

Load this skill before any `bd create`, `bd update`, or when reading beads for context.

## Resources

**CRITICAL**: You MUST `Read` the relevant resource file before proceeding:
- **Writing a bead** (`bd create`, `bd update`): Read [WRITING.md](resources/WRITING.md) first. Never write without it.
- **Reading beads for context** (planning, research): Read [READING.md](resources/READING.md) first. Never consume beads without it.
- **Exporting beads** (`/sussBead export <id>`): Read [EXPORT.md](resources/EXPORT.md) first. Follow its algorithm exactly.

| Resource                                 | When to use                                           |
|------------------------------------------|-------------------------------------------------------|
| [WRITING.md](resources/WRITING.md)       | Before any `bd create` or `bd update` call            |
| [READING.md](resources/READING.md)       | When consuming beads for context (planning, research)  |
| [EXPORT.md](resources/EXPORT.md)         | `/sussBead export <bead-id>` — export to markdown     |
| [scripts/bd-section](scripts/bd-section)                 | Extract a specific section from a bead by slug         |
| [scripts/bd-explore](scripts/bd-explore)                 | Recursive summary tree — skim a full hierarchy         |
| [scripts/bd-validate-mermaid](scripts/bd-validate-mermaid) | Validate mermaid blocks before writing beads           |

## Scripts

Shell scripts in `scripts/` for selective context loading and validation. Use full paths when invoking:

```bash
# Extract a section by slug (defaults to Summary)
~/.claude/skills/sussBead/scripts/bd-section <bead-id> [section-slug]

# Explore a full bead tree with summaries only
~/.claude/skills/sussBead/scripts/bd-explore <bead-id>

# Validate mermaid diagrams before writing (REQUIRED for any bead with mermaid)
~/.claude/skills/sussBead/scripts/bd-validate-mermaid /tmp/bead-desc.md
~/.claude/skills/sussBead/scripts/bd-validate-mermaid --string 'graph LR; A --> B'
```

## Invocations

### `/sussBead explore <bead-id>`

Explore a bead hierarchy with summaries only. Shows the full parent chain, target bead, and children — each with just their `## Summary` section. Use this to get oriented in a large bead tree without blowing the context window.

```bash
~/.claude/skills/sussBead/scripts/bd-explore $1
```
