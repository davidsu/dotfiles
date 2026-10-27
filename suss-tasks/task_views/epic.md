open
# 🗂️ Task views: open/ and done/ as symlink folders, so files stop moving

Parked. Nobody implements this yet; revisit when David is ready to migrate (his work environment
included). The owner who picks it up starts with the grill below, not with code.

## The problem (David, 2026-10-27)

A closed task moves to its effort's `done/` (`git mv`, every reference updated). David dislikes
files moving around: history, links and references churn, and the tree stops being stable.

## The idea

Every task directory keeps its files where they were created and gets view folders:

- `open/` holds a symlink for every task that is not closed
- `done/` holds a symlink for every closed task
- the links mirror the effort's file structure, so a human can walk `open/` and see only what is live

Closing a task flips one link (open → done) instead of moving the file. The same tree must be
easy to read on GitHub, where David often reads tasks, not only in a terminal. Terminal tools for
presentation are a maybe, not the goal.

## Open questions for the grill (not settled)

1. Do links live per effort (`<effort>/open/`) or once per project root? Sub-efforts: one pair per level or only at the top?
2. Does GitHub render symlinks as browsable? It shows them as files containing the target path, and does not follow them in the web tree. That may defeat "easy to traverse on GitHub": test with a throwaway repo before committing to the design
3. Who keeps the links true? A script run by the `suss-tasks` skill on every status change, a git hook, or a check that fails when a link is stale
4. What happens to the current `done/` folders and every reference to moved files (migration), including David's work environment? One migration script, dry-run first
5. Do `b44sync`, the nvim task plugin and Slack-side agents follow symlinks, or would they double-count a task that appears both as a file and as a link?
6. Title/emoji rules and the status on line 1 stay unchanged: the file is still the single source of truth, links are views only

## Where it lands when built

The `suss-tasks` skill (`~/.claude/skills/suss-tasks`: SKILL.md, resources/WRITING.md, ORGANIZATION.md) and its scripts. The "Closing moves the file" rule it records today gets replaced.

---
**Created by**: lead.home (2026-10-27), from David's idea on Telegram
**b44sync**: never
