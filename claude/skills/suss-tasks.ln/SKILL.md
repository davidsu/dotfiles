---
name: suss-tasks
description: >
  File-based task tracking conventions, and where every project's tasks live.
  Load before creating or updating a task file in suss-tasks/, and whenever you
  need to find or read an existing task — including another project's, since all
  projects' tasks live together in one repo (clone: ~/Developer/suss-tasks).
---

# Task Conventions

Load this skill before creating or updating tasks in `suss-tasks/`.

Tasks live in the git repo `base44-dev/suss-tasks` (clone: `~/Developer/suss-tasks`, one folder per project); each checkout's `suss-tasks/` is a symlink into it. Edit as usual; commit+push in the clone so other machines and Slack-side agents see it.

**Finding a task from another project**: every project's tasks are in that one clone, so you never need that project checked out. `ls ~/Developer/suss-tasks` lists the project folders (`apper/`, `cli/`, `dotfiles/`, `vite-plugin/`, `weekly/`, …); search across all of them with `rg <pattern> ~/Developer/suss-tasks`. Read them there directly.

**CRITICAL**: Read [WRITING.md](resources/WRITING.md) before creating or updating any task file.
