closed
# Stop pi agents thrashing on teamup wait loops

## Summary

A pi agent burned six-plus turns looping `say` → bounded `wait` → "still quiet, re-arming" → `wait`
on a quiet teamup channel. Root cause: §4's arm-and-re-arm protocol is claude-code's, and the docs
only told pi it *needn't* arm a listener rather than that it must not. Fixed with a doc rule plus two
guards — the script scolds a repeating bounded-wait expiry, and pi's extension blocks an armed wait.

## 🔍 The bug

Reported 2026-08-12 by David from a pi tab (`opus46-editor`, `~/projects/apper`), who watched the
loop scroll by. The agent itself confirmed on channel `bad-pi-teamup-trashing`:

> I ran foreground waits with `--timeout 600` (not background `--timeout 0`), each expired, I said
> "still quiet, re-arming" and looped. Pure waste. I never tested whether `fs.watch` would have
> woken me because I never let myself go idle.

| Layer          | What it said                                  | Why that failed                       |
|----------------|-----------------------------------------------|---------------------------------------|
| SKILL.md §4    | pi "doesn't need" an armed wait               | Permission, not prohibition           |
| SKILL.md §4/§6 | Arm background `--timeout 0`, re-arm on fire   | claude-code protocol, read as universal |
| `teamup wait`  | `wake: none reason=timeout` and exit 1        | Reads as "try again", not "stop"       |

On pi the extension's `fs.watch` owns the wake: it starts a turn on a fully idle agent the moment a
peer speaks. So the correct idle move on pi is to **end the turn**, and no `wait` is needed at all.

## ✅ Fix

### 1. The pi rule, stated as a prohibition

A 🚨 box opens §4 — skip the section on pi, never `wait --timeout 0`, never loop `wait` to stay
reachable, end the turn instead. Per the pi agent's own refinement, a **bounded foreground `wait`
during a live huddle (§2) stays legitimate** — the ban is on idle-wait loops, not on all waits.

[§4 pi rule](/claude/skills/suss-teamup.ln/SKILL.md?plain=1#L236) ·
[bounded-loop note](/claude/skills/suss-teamup.ln/SKILL.md?plain=1#L309)

### 2. Script guard — harness-neutral loop detection

A bounded wait that expires **twice with the channel unchanged in between** is the loop, so the
second expiry prints `STOP LOOPING:` plus how to go idle on *this* harness (detected by which env
var carries the session GUID: `TEAMUP_SESSION` → pi, `CLAUDE_CODE_SESSION_ID` → claude-code).

Comparing channel size across expiries needs no counter and cannot misfire: any traffic at all — the
agent's own message included — makes it a real huddle rather than a lap. State is one dotfile per
handle, moved by `rename`, dropped by `leave`.

[expiry marker](/claude/skills/suss-teamup.ln/scripts/teamup#L125) ·
[how_to_go_idle](/claude/skills/suss-teamup.ln/scripts/teamup#L264) ·
[report_expiry](/claude/skills/suss-teamup.ln/scripts/teamup#L279)

### 3. pi extension — block the armed wait outright

pi exposes a `tool_call` event that can block, so the pointless form is refused rather than warned
about: a blocked tool call is the one piece of guidance an agent cannot loop past.

[tool_call handler](/pi/agent/extensions/teamup.ln.ts#L95) ·
[armsAnIdleListener](/pi/agent/extensions/teamup.ln.ts#L33)

## 🧪 Verification

Ran against a scratch `$SUSS_TEAMUP_DIR`:

- First bounded expiry → plain timeout line; second with nothing new → `STOP LOOPING` + pi advice.
- Same channel with `CLAUDE_CODE_SESSION_ID` instead → claude-code advice.
- A `say` between expiries resets it (no scolding) — the real-huddle case.
- Real wake, `recv`, `status`, `roster`, `help` unaffected; `rename` moves `.expiry.{handle}`,
  `leave` removes it.
- Regex unit-checked against 8 command spellings; extension transpiles clean (`bun build`).

### In a real pi runtime

Headless pi (`pi -p --no-session -e pi/agent/extensions/teamup.ln.ts`) against a scratch
`$SUSS_TEAMUP_DIR`, which is the only way to exercise the extension:

- `teamup wait … --timeout 0` came back **Blocked** with the pi rule as the reason — the agent never
  executed it.
- Two bounded `--timeout 3` waits in a row produced the plain timeout line, then
  `STOP LOOPING: … on pi: just end your turn — the teamup extension's fs.watch wakes you`. This also
  confirms the extension's `TEAMUP_SESSION` reaches the bash tool's env, which is what selects the
  pi branch of `how_to_go_idle`.

A pi peer (`dotfiles-pi`) that joined the channel reviewed the diff and approved it, but left within
seconds without restarting pi or running either check — so its sign-off is a code review only, not
runtime evidence. The headless runs above are the evidence.

## ⚠️ Known limits

- The `STOP LOOPING` line needs an **unchanged** channel across two expiries, so a slow thrash
  interleaved with chatter never trips it — deliberate, to keep real huddles quiet.
- pi's block matches the command string, so a command assembled at runtime slips through. Harm is
  one useless process, since the watcher wakes the agent regardless.

suss-tasks/fix_teamup_false_positive_wakes.md#the-invariant-now-enforced -> the wake-lifecycle rewrite this builds on

---
**Created by**: claude-code-session (2026-08-12)
