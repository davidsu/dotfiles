---
name: suss-slack-post
description: >
  Post or edit a Slack message AS David (his session), after showing him the draft rendered
  the way Slack will show it. Load before an agent writes directly to a Slack channel or thread
  for people to read. NOT for suss-teamup channel messages (say/ask/ack), even though the
  teamup bridge mirrors those into Slack.
---

# suss-slack-post

Everything you post lands under David's name, so it must read like him: short, clear, linked.

```
S=~/.claude/skills/suss-slack-post/scripts/slack-post
$S check draft.md                                        # show the draft as Slack will, lint it
$S send  draft.md --channel C… [--thread TS]              # post, read back, print the permalink
$S send  draft.md --channel C… [--thread TS] --image shot.png
$S send  draft.md --channel C… [--thread TS] --update TS  # edit in place, keeps its files
# --unsigned on check and send when David wants no signature
```

## 🗣️ Reading David

When David writes `[text](link)`, `text` is the clickable label for `link`: the label shows,
the URL hides. Keep it that way in the post and in every draft you show him.

## ✍️ The draft

One file, one line per Slack line:

| Write            | Slack shows                                          |
|------------------|------------------------------------------------------|
| `[label](url)`   | `label`, clickable                                    |
| `@[Full Name]`   | a real @tag (full or display name, must be unique)    |
| `` `code` ``     | inline code                                          |
| `_text_`         | italic                                               |
| `- item`         | a bullet                                             |
| a lone URL line  | that link                                            |

- **Short.** Lead with the point. One point per line. Details only on request.
- **Link every claim** with a label: no bare URLs in a sentence, no local paths, no code fences.
- **Sign** with a last line `_agent: <your handle>_`, unless David asks for no signature.
- **Tag people** only when David asks you to.

`check` blocks what breaks the post (fences, paths, bare URLs, a missing signature, a name that
matches nobody) and notes what is just long.

Situation-specific rules live in `resources/`. Read the one that fits before drafting:

- `resources/pr-posts.md`: posts about pull requests (new PR, review replies, re-review nudges).

## 👀 Show David the draft

Paste `check`'s output **verbatim into your reply**. It is a markdown blockquote, so the
terminal shows labels and hides URLs, the way Slack will. Never wrap it in a code fence: that
shows raw markup. If David may be away from your terminal, also put the draft where he can see
it (e.g. your teamup channel).

## 🔁 Improve this skill

If your session with David taught a lesson worth keeping for future posts, propose a change to
this skill and agree it with him before editing. Use your judgement on what is worth it and
where it belongs: general rules here, rules for one kind of post in `resources/`, script fixes
in `scripts/`. Keep it lean.

`resources/mechanics.md` explains what `send` does and the Slack API traps, for when you
change the script.
