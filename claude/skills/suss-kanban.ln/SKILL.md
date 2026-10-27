---
name: suss-kanban
description: >
  Open the susskanban board of a tasks folder in the user's browser: runs `suss-kanban` in the
  right directory (the folder holding the efforts, usually a project's suss-tasks/). Invoke as
  /suss-kanban [dir].
allowed-tools: Bash
---

# suss-kanban

```
cd <tasks dir> && suss-kanban
```

`suss-kanban` (alias of `susskanban`, both in `~/.dotfiles/bin`) opens the board of the current
folder and starts a background server for it unless one already serves that folder.
`suss-kanban killall` stops every server.

- `<tasks dir>`: the folder whose efforts the user wants on the board. Given in the invocation → use it.
  Otherwise the `suss-tasks/` of the project you work in (its pwd or worktree). Not sure which → ask,
  don't guess: there are several roots (a project's `suss-tasks/`, `~/Developer/suss-tasks`,
  `~/.dotfiles/suss-tasks`, the private susskind one).
- Run it from your own Bash tool, then tell the user the URL it printed.
