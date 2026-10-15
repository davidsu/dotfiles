# Task Organization

How tasks are told apart at a glance, on the b44sync board and in a directory listing. The
board shows titles only, so when several epics advance in parallel every row looks the same.
This file holds the visual conventions that fix that. It grows as new needs show up (task
types are the next candidate, see the `dotfiles/suss_tasks_metadata` epic in suss-tasks).

## 🎨 One emoji per epic (David, 2026-10-13)

Every epic directory owns **one emoji**, and **every task file in that directory, the `epic.md`
and everything inside it, sub-directories included, starts its title with that emoji**:

```
open
# 🔒 Protected main: composer shows a locked Main badge + Create branch send
```

The emoji is the first character of the `# ` title line. Line 1 stays the bare status: the
sync tool, the nvim task plugin and the hooks parse it, and the board shows the title, which
is where the emoji is needed.

### Rules

1. **One epic, one emoji; one emoji, one open epic.** Pick an emoji no other open epic uses.
   List what is taken before choosing:
   ```
   cd ~/Developer/suss-tasks && for f in */*/epic.md; do s=$(head -1 "$f"); case "$s" in closed) ;; *) echo "$(sed -n 2p "$f" | cut -c3-4)  $(dirname "$f")";; esac; done
   ```
   A closed epic frees its emoji.
2. **It stands for the epic**, not for a task type or status: a lock for protected branches.
   Anyone seeing the row should guess which epic it belongs to.
3. **Single code point.** Avoid emojis that need a variation selector or a ZWJ sequence
   (🖥️, 🏷️, 👨‍💻): they count as 2+ characters, render inconsistently in terminals, and
   break column alignment. Prefer 🔒 💻 📦 📰 📣 🎬 🧩 📅 🧹 🎨 👻 📜.
4. **Same emoji in every file of the directory**, including files added later and files
   moved into `done/`. A new task file copies the emoji from its epic's title.
5. **The emoji is part of the title everywhere**: the b44sync task title (`suss-sync-tasks`
   takes the `# ` heading as is), the weekly's links, PR bodies that quote the task. Don't
   strip it.
6. **Renaming the emoji** (a clash found later) means editing every file in the directory and
   pushing each tracked one with `suss-sync-tasks push`, so choose once.

### Applying it to an existing epic

Change the title of every `.md` under the directory, then publish and push the tracked files
whose status is not `closed` (the active board). Closed files take the new title locally and
reach the board on their next push, if ever:

```
cd ~/Developer/suss-tasks
E=🔒 D=apper/restricted_mode_ui
rg -l --glob '*.md' '^# ' "$D" | xargs sed -i "0,/^# /{s/^# \($E \)\?/# $E /}"
bin/sync "$D: epic emoji $E on every title" "$D"
for f in $(rg -l --glob '*.md' '^# ' "$D"); do case "$(head -1 "$f")" in closed) ;; *) python3 ~/.claude/skills/suss-sync-tasks/sync.py push "$f";; esac; done
```

The `sed` is idempotent: a title that already carries the emoji is left alone.
