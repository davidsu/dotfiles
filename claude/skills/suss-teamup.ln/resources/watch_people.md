# watch_people — model-free people watch

`scripts/watch_people` posts one teamup line per new item of GitHub or Slack activity by given
people: `<who> <what> <permalink>`. There is no model and no interpretation. It replaces a lead's
"watch X" cron. Flags: `scripts/watch_people --help`.

A lead starts it as a long-lived **background** command and stops it with SIGTERM, which posts a `bye`:

```
~/.claude/skills/suss-teamup/scripts/watch_people --channel <team channel> --to <lead handle> \
  --github-users ChenLevy650 --github-search 'repo:base44-dev/apper commenter:ChenLevy650' \
  --slack-users U095Y2SD7KQ,U09UMSKSX0X --slack-channels C0BR35HS0HK,D0AEDVDDQJY --slack-feeds D0B8HFL81GX
```

- **What it reads.** GitHub through `gh`: issue comments, review comments and reviews by
  `--github-users` on the watched PRs (a search keeps its 30 most recently updated: leave out `is:open`, or a merged PR drops out before its merge is posted), and any PR that got merged. Slack through David's keychain
  session (`suss-communication/scripts/slack_session.py`): `conversations.history` plus the
  replies of threads started in the last 14 days. It doesn't use search, because search misses bot DMs.
  `--slack-feeds` channels count every message, whoever wrote it (D0B8HFL81GX is the b44sync bot DM:
  task-comment notifications).
- **Who wakes.** `--to <handle>` @-addresses each line. Without it, only the rules in SKILL.md
  "Who gets woken" apply. Posts are not mirrored to Slack.
- **State.** `~/.local/state/suss-teamup/watch_people/<channel>.<handle>.json` keeps the ids it
  posted (30 days) and the time it started. A restart posts what arrived while it was down and
  never repeats an item. `--since 24h` looks further back on the first run.
- **Failures.** A network or API error is logged to stderr and the source is retried next period.
- **Try it first.** `--dry-run --since 24h` prints what it would post and exits.
