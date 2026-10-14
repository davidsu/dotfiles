---
name: suss-communication
description: >
  Send or edit a message AS David, on Slack or WhatsApp, after showing him the draft the way
  it will look. Load before an agent writes to a Slack channel/thread or a WhatsApp chat for
  people to read. NOT for suss-teamup channel messages (say/ask/ack), even though the teamup
  bridge mirrors those into Slack.
---

# suss-communication

Everything you send lands under David's name, so it must read like him: short, clear, linked.

## 📡 Pick the channel

Read the resource for the channel before drafting:

| Channel  | Read                                           |
|----------|------------------------------------------------|
| Slack    | [resources/slack.md](resources/slack.md)       |
| WhatsApp | [resources/whatsapp.md](resources/whatsapp.md) |

## 🗣️ Reading David

When David writes `[text](link)`, or `(text)[link]` when typing fast, `text` is the clickable label for `link`: the label shows,
the URL hides. Keep it that way on Slack. WhatsApp has no labeled links: there it becomes
`Label: url` on its own line ([resources/whatsapp.md](resources/whatsapp.md), Links).

## ✍️ Every message

- **Short.** Lead with the point. One point per line. Details only on request.
- **Sign** with a last line `_agent: <your handle>_`, unless David asks for no signature.
- **Tag people** only when David asks you to.

## 👀 Show David the draft

Show David the draft before it goes out, rendered the way the channel will show it (the
channel's resource says how). If David may be away from your terminal, also put the draft where
he can see it (e.g. your teamup channel).

## 🔁 Improve this skill

If your session with David taught a lesson worth keeping for future messages, propose a change
to this skill and agree it with him before editing. Use your judgement on what is worth it and
where it belongs: rules for every channel here, rules for one channel in its resource, script
fixes in `scripts/`. Keep it lean.
