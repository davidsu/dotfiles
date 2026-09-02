---
name: suss-tasks
description: >
  File-based task tracking conventions. Load before creating or updating
  task files in suss-tasks/.
---

# Task Conventions

Load this skill before creating or updating tasks in `suss-tasks/`.

Tasks live in the git repo `base44-dev/suss-tasks` (clone: `~/Developer/suss-tasks`, one folder per project); each checkout's `suss-tasks/` is a symlink into it. Edit as usual; commit+push in the clone so other machines and Slack-side agents see it.

**CRITICAL**: Read [WRITING.md](resources/WRITING.md) before creating or updating any task file.
