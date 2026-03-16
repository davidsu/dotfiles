---
name: suss-tasks
description: >
  File-based task tracking conventions. Load before creating, updating, or
  reading tasks in suss-tasks/. Covers file format, status lifecycle, directory
  structure, inline source attribution, and navigation conventions.
---

# Task Conventions

Load this skill before creating, updating, or reading tasks in `suss-tasks/`.

## Resources

**CRITICAL**: Read [WRITING.md](resources/WRITING.md) before creating or updating any task file.

## Exploring Tasks

```bash
# Find all open tasks
rg '^open$' suss-tasks/ -l

# Find in-progress work
rg '^in_progress$' suss-tasks/ -l

# Find blocked tasks
rg '^blocked$' suss-tasks/ -l

# Tasks in a specific epic
ls suss-tasks/epic-name/

# Search task content
rg 'search term' suss-tasks/

# Read a task's status
head -1 suss-tasks/epic-name/task-name.md
```

## Epic Traversal

**Before working on any task under a directory, read all ancestor `epic.md` files first.** Walk up from the task's directory to `suss-tasks/`, reading every `epic.md` you find. Root epic gives broadest context, each level narrows scope.

For `suss-tasks/a/b/c/task.md`, read in order:
1. `suss-tasks/a/epic.md`
2. `suss-tasks/a/b/epic.md`
3. `suss-tasks/a/b/c/epic.md`
4. `suss-tasks/a/b/c/task.md`

## Contradiction Escalation

**If you find contradicting information between tasks: STOP.** Do not resolve it yourself. Escalate to the user with the conflicting file paths and quoted contradictions. Wait for instructions.
