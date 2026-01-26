# Agent Instructions

## Issue Tracking

This project uses **bd (beads)** for issue tracking.

**Hooks are installed** - Claude Code automatically injects `bd prime` context at session start.

**Quick reference:**
- `bd ready` - Find unblocked work
- `bd create "Title" --type task --priority 2` - Create issue
- `bd close <id>` - Complete work
- `bd sync` - Sync with git (run at session end)

For manual workflow details: `bd prime`

## Session Completion

**When ending a work session:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Update issue status** - Close finished work, update in-progress items
3. **Run bd sync** - Sync beads database to JSONL
4. **Hand off** - Provide context for next session

**Note:** User handles git commits and pushes manually

