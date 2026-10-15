---
name: suss-tasks
description: >
  File-based task tracking conventions, and where every project's tasks live.
  Load before creating or updating a task file in suss-tasks/, and whenever you
  need to find or read an existing task — including another project's: company
  projects' tasks live together in one repo (clone: ~/Developer/suss-tasks),
  David's own repos (dotfiles, susskind) hold theirs in a committed suss-tasks/ dir.
---

# Task Conventions

Load this skill before creating or updating tasks in `suss-tasks/`.

Company projects (`apper/`, `cli/`, `vite-plugin/`, `weekly/`) keep their tasks in the git repo `base44-dev/suss-tasks` (clone: `~/Developer/suss-tasks`, one folder per project), because those repos cannot take a `suss-tasks/` directory: each checkout's `suss-tasks/` is a symlink into the clone, git-ignored there (`.git/info/exclude`). Edit as usual, then publish with `~/Developer/suss-tasks/bin/sync "<commit message>" <paths…>` (paths relative to the clone root; no paths = pull + push now) so other machines and Slack-side agents see it. Never `git pull` / `git push` by hand in that clone: many agents share it, and concurrent pulls corrupt `FETCH_HEAD` ("Cannot rebase onto multiple branches"); `bin/sync` takes a lock and commits only the paths you name.

**The push and the b44sync board push run in the background** (the repo's `post-commit` hook): `bin/sync` returns right after the commit and prints a `bin/sync-wait <sha>` command. Run that command as a **background** command (Claude Code: `run_in_background`); it exits when the push + board sync of your commit end, prints the log, and exits 1 on failure (git push failed, or `sync.py push` refused a file, e.g. unlinked references): fix and `bin/sync` again. Board pushes follow the suss-sync-tasks scope rules, so don't run `sync.py push` yourself for a file you just synced. An unread failure is printed by every later `bin/sync` until `bin/sync-wait <sha>` reads it.

**David's own repos hold their tasks natively**, no symlink, no `bin/sync`: `~/.dotfiles/suss-tasks/<epic>/` and `~/projects/apper/susskind/suss-tasks/<epic>/` are committed directories in those repos. Edit, then `git commit` + `git push` straight to that repo's branch (`master` / `main`), never a PR. `davidsu/dotfiles` is **public**: a dotfiles task that carries work detail (Slack channels, tickets, colleagues, company tooling) goes to `~/projects/apper/susskind/suss-tasks/dotfiles/<epic>/` instead, which is private.

**Finding a task from another project**: company tasks are all in the one clone, so you never need that project checked out. `ls ~/Developer/suss-tasks` lists the project folders (`apper/`, `cli/`, `vite-plugin/`, `weekly/`, …). Search all three roots at once: `rg <pattern> ~/Developer/suss-tasks ~/.dotfiles/suss-tasks ~/projects/apper/susskind/suss-tasks`. Read them there directly.

**Only project tasks sync to the b44sync board**: `apper/`, `cli/`, `vite-plugin/` (a top-level dir with a matching `~/projects/<name>` repo); `weekly/` and every task in dotfiles or susskind are David's own and `/suss-sync-tasks` refuses them, so give such a task the footer `**b44sync**: never`.

**Every task gets its own directory with an `epic.md`** — never a single loose `.md` file under `suss-tasks/<project>/`.

**Every epic directory owns one emoji, and every title in it starts with that emoji** (`# 🔒 …`), so the b44sync board tells parallel epics apart. Rules and how to apply it: [ORGANIZATION.md](resources/ORGANIZATION.md).

**A task with a PR carries its url**: a `**PR**: [#N](https://github.com/<owner>/<repo>/pull/N)` line above the authorship footer, written by the agent who opens the PR ([WRITING.md, PR Line](resources/WRITING.md#pr-line)).

**CRITICAL**: Read [WRITING.md](resources/WRITING.md) before creating or updating any task file.
