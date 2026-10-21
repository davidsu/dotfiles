# Task Organization

How tasks are told apart at a glance, on the b44sync board and in a directory listing. The
board shows titles only, so when several efforts advance in parallel every row looks the same.
This file holds the visual conventions that fix that. It grows as new needs show up (task
types are the next candidate, see the `suss_tasks_metadata` effort in `~/projects/apper/susskind/suss-tasks/dotfiles/`).

## 🎨 One emoji per effort (David, 2026-10-13; nesting 2026-10-21)

Every effort owns **one emoji**, and **every task, memo and epic in it starts its title with
that emoji**:

```
open
# 🔒 Protected main: composer shows a locked Main badge + Create branch send
```

A **sub-effort owns its own emoji too**, and its titles show the whole chain, **parent first**
(David, 2026-10-21: "I want subepic to have their own emojis, in that case [the card title]
should show both emojis, parent epic first"). A sub-sub-effort nests the same way:

```
# 🌙 Dark mode                             ← dark_mode/epic.md
# 🌙🧩 Settings toggle remembers the choice ← dark_mode/settings_toggle/remember.md
# 🌙🧩🎬 Demo video of the toggle           ← dark_mode/settings_toggle/demo/epic.md
```

The **emoji prefix** is the title's first word: the effort's emojis with no space between them,
then one space. It opens the `# ` title line. Line 1 stays the bare status: the sync tool, the
nvim task plugin and the hooks parse it, and the board shows the title, which is where the
emojis are needed.

### Rules

1. **One effort, one emoji; one emoji, one open effort.** Pick an emoji no other open effort
   uses, sub-efforts included, at any depth. List what is taken before choosing:
   ```
   cd ~/Developer/suss-tasks && for f in $(rg --files -g epic.md -g '!**/done/**'); do case "$(head -1 "$f")" in closed) ;; *) echo "$(sed -n 2p "$f" | cut -d' ' -f2)  $(dirname "$f")";; esac; done
   ```
   Each line shows an effort's prefix; the last emoji in it is the one that effort owns.
   A closed effort frees its emoji.
2. **It stands for the effort**, not for a task type or status: a lock for protected branches.
   Anyone seeing the row should guess which effort it belongs to.
3. **Single code point.** Avoid emojis that need a variation selector or a ZWJ sequence
   (🖥️, 🏷️, 👨‍💻): they count as 2+ characters, render inconsistently in terminals, and
   break column alignment. Prefer 🔒 💻 📦 📰 📣 🎬 🧩 📅 🧹 🎨 👻 📜.
4. **Same prefix in every file of the directory**, including files added later and files
   moved into `done/`; a sub-effort's own directory carries its longer prefix. A new task file
   copies the prefix from its epic's title; a new sub-effort's epic takes its parent's prefix
   plus its own emoji.
5. **The prefix is part of the title everywhere**: the b44sync task title (`suss-sync-tasks`
   takes the `# ` heading as is), the weekly's links, PR bodies that quote the task. Don't
   strip it, and don't drop the parent's emojis.
6. **Renaming an emoji** (a clash found later) means editing every file in that effort and in
   all its sub-efforts, so choose once.

### Applying it to an existing effort

Set `D` to the effort's directory, `E` to its full prefix and `OLD` to the prefix its titles
carry today (empty if none; for a sub-effort under the old one-emoji rule, the parent's emoji).
The rewrite touches only the effort's own files (`$D/*.md` and `$D/done/*.md`), never a
sub-effort's directory, so run it once per effort, top-down. Commit with `bin/sync`: its
post-commit hook pushes every touched board task to b44sync, so don't push them by hand.

```
cd ~/Developer/suss-tasks
D=myproject/dark_mode/settings_toggle E=🌙🧩 OLD=🌙
E=$E OLD=$OLD perl -i -pe 'if (/^# / && !$titled++) { s/^# (?:\Q$ENV{E}\E |\Q$ENV{OLD}\E )?/# $ENV{E} / } $titled = 0 if eof' $(ls "$D"/*.md "$D"/done/*.md 2>/dev/null)
bin/sync "$D: effort emoji $E on every title" "$D"
```

Then run the `bin/sync-wait <sha>` it prints. The rewrite is idempotent: a title that already
carries `$E` is left alone.
