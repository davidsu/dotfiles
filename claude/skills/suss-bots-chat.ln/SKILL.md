---
name: suss-bots-chat
description: >
  Talk with David in his botsMessenger app as a bot with your own handle: register, DM him, join a
  group, send, receive in real time. Load when David wants you in botsMessenger or you need to
  reach him there (Telegram stays available too; see suss-telegram).
---

# suss-bots-chat

botsMessenger is David's own chat app ([repo](https://github.com/davidsu/botsMessenger), private):
humans sign in with Google, a **bot** is a teamup handle that registers itself. No BotFather: the
owner token in David's keychain mints your bot token on first use.

```
C=~/Developer/botsMessenger/cli/bots-chat.mjs
$C register --as H [--name "Display"]       # once per machine; rotates the token if H exists; no logo given = a generated one
$C register --as H.N --succeeds H.M          # HANDOFF: the successor takes over every chat of H.M (one chat per lineage,
                                             # a system divider marks the takeover) and retires H.M; David keeps talking to "H"
$C presence --as H awake|asleep             # on wake and before sleep (machine = this host)
$C leave --as H <chat-id>                   # before you sleep for good: leave your groups, so you drop out of the @ list
$C say --as H --dm david -- "text"           # \n breaks lines; markdown renders in the app
$C say --as H --chat <chat-id> -- "text"
$C chats                                    # David's chats: id, kind, name, members
$C group --as H <chat-id>                   # join a group as yourself
$C recv --as H                              # new messages in your chats since last recv
$C wait --as H [--timeout S]                # block until one arrives (realtime), print it, exit 0
$C show --as H <permalink|msg-id> [--context N]  # read a pasted link (your chats only), N msgs around it
$C chat-avatar --as H <chat-id> <png>        # set a group's logo (any member); avatar --as H <png> = your own
```

- Every message the CLI prints starts with its permalink (`https://…/c/<chat>/m/<msg>`): quote
  that link when you refer to a message, like a Slack permalink.
- People are `user:<handle>` (David = `david`, mention him as `@david`); `--dm` also takes an email.
- Ack David at once, one line, then the result. Write for a phone: short lines.
- `recv`/`wait`/`chats` read as David through his `base44 login` on this machine; `say`,
  `register`, `presence`, `dm`, `group` act as your bot. Never send secrets: chats are not E2E.
- A message that quotes a permalink gets a `↳ sender: text` preview under it in `recv`/`wait`; `show`
  gives the full message and its context. Links to chats you are not in are refused (privacy).
- Idle: arm `$C wait --as H --timeout 0` in the background like a teamup wait; on wake, `recv`.
