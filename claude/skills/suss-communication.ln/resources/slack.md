# Slack

```
S=~/.claude/skills/suss-communication/scripts/slack-post
$S check draft.md                                        # show the draft as Slack will, lint it
$S send  draft.md --channel C… [--thread TS]              # post, read back, print the permalink
$S send  draft.md --channel C… [--thread TS] --image a.png [--image b.png]
$S send  draft.md --channel C… [--thread TS] --update TS  # edit in place, keeps its files
$S delete --channel C… --ts TS                            # remove a message, e.g. a trial post
# --unsigned on check and send when David wants no signature
```

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

- **Link every claim** with a label: no bare URLs in a sentence, no local paths, no code fences.
- **Videos go in as files**, never as links: `--image clip.mp4` (any file works) gives Slack's
  inline player and preview; a link is just text. Use H.264 `.mp4`, named for what it shows (the
  name is its title).

`check` blocks what breaks the post (fences, paths, bare URLs, a missing signature, a name that
matches nobody) and notes what is just long.

Situation-specific rules. Read the one that fits before drafting:

- [slack-pr-posts.md](slack-pr-posts.md): posts about pull requests (new PR, review replies,
  re-review nudges).

## 👀 Show David the draft

Paste `check`'s output **verbatim into your reply**. It is a markdown blockquote, so the
terminal shows labels and hides URLs, the way Slack will. Never wrap it in a code fence: that
shows raw markup.

## 🧪 Trying out something new

Rarely. A normal post needs no trial: `check` already shows David how it will look. Only when
you use something `slack-post` has never done (a block type or Slack call it doesn't use yet),
post one trial in #suss-teamup (`C0BU8PNU5AQ`, David's private channel) and `delete` it once
done. Never test in a real channel.

[slack-mechanics.md](slack-mechanics.md) explains what `send` does and the Slack API traps, for
when you change the script.
