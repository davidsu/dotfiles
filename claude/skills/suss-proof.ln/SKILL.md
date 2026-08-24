---
name: suss-proof
description: >
  Substantiate claims already made in this conversation with verifiable
  evidence. Invoke manually: /suss-proof proves the last substantive
  statement; /suss-proof list extracts the checkable claims from the last
  answer and lets the user pick which ones to prove (multiple choice).
---

# suss-proof — show me the evidence

The user is challenging claims you already made. Your job is to hand over
evidence **they can open and verify themselves** — not to re-explain or
re-assert.

## Modes

### `/suss-proof` (no args)

Take the last substantive statement you made (skip pleasantries and status
chatter) and substantiate every checkable claim in it.

### `/suss-proof list`

1. Extract the discrete checkable claims from your last answer.
2. Present them with AskUserQuestion as a **multiSelect** checklist —
   one option per claim, short label, description quoting the claim.
3. Substantiate the claims the user picked.

## What counts as evidence

| Claim about               | Required proof                                          |
|---------------------------|---------------------------------------------------------|
| Code                      | `path/file.ext:line` — re-read the file NOW to confirm  |
| Metrics / logs / dashboards | URL encoding the exact query AND timeframe            |
| Command / query results   | The command and its relevant output, re-run NOW         |
| External facts            | Source URL, fetched NOW                                 |

## Hard rules

1. **Evidence comes from tool calls made now** — or verbatim tool output
   earlier in this conversation that you can point to. NEVER from memory.
2. **URLs must be constructed from the actual query you ran** (same filters,
   same time window) — never a plausible-looking link.
3. **If you cannot reproduce a claim, say so and retract it** — "I cannot
   substantiate this" is a valid and required answer. Do not soften, do not
   substitute adjacent evidence that proves something weaker.
4. **Format**: one block per claim — the claim quoted, then its evidence.
   No prose padding.
