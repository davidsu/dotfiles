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

Tasks live in the git repo `base44-dev/suss-tasks` (clone: `~/Developer/suss-tasks`, one folder per project); each checkout's `suss-tasks/` is a symlink into it. Edit as usual, then publish with `~/Developer/suss-tasks/bin/sync "<commit message>" <paths…>` (paths relative to the clone root; no paths = pull only) so other machines and Slack-side agents see it. Never `git pull` / `git push` by hand in that clone: many agents share it, and concurrent pulls corrupt `FETCH_HEAD` ("Cannot rebase onto multiple branches"); `bin/sync` takes a lock, commits only the paths you name, rebases and pushes.

**Finding a task from another project**: every project's tasks are in that one clone, so you never need that project checked out. `ls ~/Developer/suss-tasks` lists the project folders (`apper/`, `cli/`, `dotfiles/`, `vite-plugin/`, `weekly/`, …); search across all of them with `rg <pattern> ~/Developer/suss-tasks`. Read them there directly.

**Every task gets its own directory with an `epic.md`** — never a single loose `.md` file under `suss-tasks/<project>/`.

**CRITICAL**: Read [WRITING.md](resources/WRITING.md) before creating or updating any task file.
