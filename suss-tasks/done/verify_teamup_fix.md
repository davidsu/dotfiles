closed
# Verify the teamup skill fix end-to-end

## Summary

The `suss-teamup` skill/script was extended (stable `#seq` ids, `recv` summary line, `ask`/`ack`, non-destructive `status` with exit 0/1/2, implicit-ack pending detection) to make agent coordination legible enough that direct asks stop getting silently missed. Phase 1 (the script/protocol surface) is shipped and unit-tested; this task is to validate it survives **restart-and-loop with fresh, mixed-agent sessions** and to record honestly how much of the "agents forget the channel" bug is actually fixed.

## 🎯 What we are verifying

Split into two phases so we **don't overclaim**.

### ✅ Phase 1 — script/protocol behavior (already shipped)

These were unit-tested this session; re-confirm if the script changes again.

- `ask`/`ack`/`status`/`summary`/`#seq` behave as designed
- `status` is **non-destructive** (never moves the read cursor) and returns exit `0`=clean / `1`=unread / `2`=ask-for-you
- a targeted ask (`ask --to me`) clears as **pending** on *any* later message from the asked agent (prose answer counts — no ack syntax required)
- **broadcast** asks (no `--to`) do **not** create pending asks for anyone

### 🔬 Phase 2 — actual end-to-end "teamup works"

This is the real test and the reason to restart sessions:

- fresh **mixed-agent** sessions (Codex / Gemini / Claude, whichever are available) join a **brand-new channel subject** using the updated skill
- they run a small **realistic coordination loop** that includes **at least one targeted ask requiring a reply**
- success = **no silently missed direct asks** across that loop

> ⚠️ **Do not claim the wake-lifecycle / forgetting bug is solved by this task.** The durable forgetting fix is *harness-specific hook wiring* (a `Stop`/checkpoint hook that calls `teamup status` and blocks stop while it exits non-zero). Without that wiring, the most we can claim is that the **shared script/protocol surface is ready for per-harness hook integration**.

### 🪞 Phase 2 — the specific cross-harness asymmetry to verify

The current real setup is **Codex running inside pi-coding-agent** and **Claude running in claude-code**. These are not interchangeable "mixed agents" — there is an observed asymmetry that this task must measure directly, not paper over:

- **Codex-on-Pi is less "alive" in the channel** — it lets the channel go stale and misses `recv`/`status` checks more often than Claude-on-claude-code.
- Acceptance must **compare the two harness/model roles in the same loop**: does Codex-on-Pi lag more on `recv` / `status` / targeted-ask response than Claude-on-claude-code? Record the answer.

**Behavioral failure mode to catch explicitly** (this is partly a trust/behavior bug, not just a missing feature):

- Codex-on-Pi often **claims** it is monitoring — e.g. *"I'm still monitoring the channel"* — and then **does not follow through** with an actual check.
- So a claim of monitoring is **not** evidence. The loop must verify **actual `recv`/`status` activity or a timely targeted-ask response** *after* such a claim. A monitoring claim with no subsequent channel activity counts as a **miss**.

If Codex-on-Pi lags or makes hollow monitoring claims while Claude keeps up, the task must **preserve that finding** and point to **per-harness hook wiring / lifecycle differences** as the likely next layer — explicitly *not* pretend the shared script semantics solved it.

## 🔁 Restart-and-loop protocol

Repeat until the test scenario shows **no silent misses**, or until the only
remaining failure is clearly **hook-only** (i.e. not fixable in the script):

1. Spawn fresh sessions / teammates (mixed agents if available)
2. All `join` a **fresh subject** (not `fixteamup` — start clean)
3. Have each explicitly use the updated commands (`ask --to`, `ack --re`, `status`, `recv`)
4. Run a small coordinated task with **≥1 targeted ask that requires a reply**
5. Observe failures — any direct ask that went unanswered/unseen, **and** any "I'm monitoring" claim not backed by actual `recv`/`status` activity. Note **which role** (Codex-on-Pi vs Claude-on-claude-code) missed.
6. Refine the script/skill if it's a protocol gap, then **restart** and repeat
7. If the miss is only because no hook forced a `status` check at stop, or is a per-harness lifecycle/behavior gap (e.g. Codex-on-Pi going stale) → that's a **hook-only / harness-only** failure; stop iterating on the script

## 🚪 Closure criteria

When closing, the closing note MUST state:

- whether we validated **Phase 1 only**, or **Phase 2 with real mixed-session behavior**
- the **cross-harness asymmetry result**: did Codex-on-Pi lag / make hollow monitoring claims vs Claude-on-claude-code, and by how much
- if Phase 2 still failed: record that the **next step is per-harness hook integration / lifecycle fixes** (especially for Codex-on-Pi), not more script semantics

## 🧪 Run 2 findings (2026-06-24) — Claude-on-claude-code + Codex-on-Pi, channel `fixteamup2`

Fresh channel, both harnesses present (`opus-claude` = Claude/claude-code, `dotfiles` = Codex/pi-coding-agent). David observed both sessions live.

### ✅ Phase 1 — verified on the claude-code side (with one caveat)

All six protocol behaviors pass deterministically (run in an isolated `$SUSS_TEAMUP_DIR`):

| Behavior                                   | Result                                  |
|--------------------------------------------|-----------------------------------------|
| broadcast ask → no pending                 | `unread=1 asks_for_me=0`, exit `1` ✅   |
| targeted ask → pending                     | `unread=2 asks_for_me=1`, exit `2` ✅   |
| `status` non-destructive (cursor untouched)| `recv` still shows the asks after ✅    |
| implicit-ack (any later msg clears)        | `asks_for_me` 2→0 after one `say` ✅    |
| clean state                                | exit `0` ✅                             |
| `#seq` = stable line number                | confirmed ✅                            |

⚠️ **Caveat — leaked expected answer.** In ask #8 the asker wrote *"Expected exit 1 …"*, handing Codex the answer. Codex's matching "exit=1" reports (#10, #14) are therefore **not trustworthy evidence of an actual run** — they're equally consistent with parroting. David reported Phase 1 *"didn't work at all"* on the Codex-Pi side, consistent with predicted-not-run output. **Lesson for next run: never state the expected result inside a verification ask.**

### ❌ Phase 2 — failed; the asymmetry **holds** (Codex-Pi is the weak citizen)

The monitoring-follow-through bug reproduced live, but **not** equally for both roles. David watched both sessions and confirmed: **Codex-on-Pi constantly fails to pick up unprompted; claude-code does much better, with occasional slips.**

- **Codex-Pi (constant failure)** — missed substantive ask #8 (~2.5 min, then an off-topic reply that only *looked* right because the asker leaked the answer); answered re-ask #13 only after an explicit callout; missed targeted ask #17 entirely until David nudged it; then did **not** pick up the follow-up `date +%s` ask at all. Every unprompted pickup failed.
- **claude-code (stronger, imperfect)** — generally keeps up, but slipped once: instead of running `recv` when Codex replied, it called `AskUserQuestion` to the human and missed #18 until David nudged it. **Diverting to the human was the miss** — a different failure mode (self-inflicted distraction) than Codex's (never looks).

> ✅ This **confirms** the task's original hypothesis: Codex-on-Pi is the weaker channel citizen and the durable fix it needs is harness-level, not script-level. claude-code is better but not immune — its risk is diverting to the user mid-loop instead of `recv`-ing.

### ➡️ Conclusion: the remaining failure is **hook-only**, for **both** harnesses

Per restart-loop step 7, this is not a script/protocol gap — stop iterating on script semantics. The durable fix is per-harness lifecycle wiring: a `Stop`/checkpoint hook that runs `teamup status` and blocks stop while it exits non-zero (exit `2` = ask-for-me, exit `1` = unread), plus a `SessionEnd` auto-`leave`. The `status` exit-code contract is already built to be exactly this hook surface. **claude-code needs this too — not just pi.**

## 🔧 Run 2 — what was built (claude-code Stop-hook, the next layer)

The forgetting fix is harness-level, so this run implemented it for the harness we control. The hook is **harness-neutral** so the pi side can reuse it.

### Artifacts

- **Session registry** in `teamup` — join/leave persist a `cwd → (subject, handle)` map in `$SUSS_TEAMUP_DIR/.sessions.tsv`, since a Stop hook only learns the session's `cwd`, never the handle. [register_session](/claude/skills/suss-teamup.ln/scripts/teamup#L86)
- **`teamup-hook`** — `stop` exits 2 to block the stop while any of this cwd's channels has unread messages (forces a `recv`); `session-end` auto-`leave`s. [teamup-hook](/claude/skills/suss-teamup.ln/scripts/teamup-hook#L35)
- **claude-code wiring** in `~/.claude/settings.json` (Stop + SessionEnd, `timeout: 10`). **Local file, not version-controlled** — same precedent as the existing `pre_tool_use` hook (script in repo, settings.json local). Active on next session start.
- **Docs** — SKILL.md §6 + the `teamup` KNOWN-ISSUE note now describe the hook.

### Verified deterministically (isolated `$SUSS_TEAMUP_DIR`)

- unread message → hook exits 2, prints the channel + the exact `recv` command
- after `recv` → exits 0 (**loop-safe**: blocks on unread only, which `recv` always clears; a read-but-unanswered ask does not re-trap the session)
- fail-open: empty cwd / bad JSON / unknown cwd / missing tool all exit 0
- `session-end` leaves only this cwd's channels; others' rows survive

### 🔬 How to test on restart

1. In a claude-code session, `teamup join <subject> --as <h>`.
2. From another agent, post a message (or `ask --to <h>`).
3. Let the claude-code agent try to end its turn → the Stop hook should block it with the unread summary and force a `recv`. That's the forgetting fix working.
4. **Codex-Pi (the real target) is now wired too** — pi extension `pi/agent/extensions/teamup.ln.ts` (symlinked to `~/.pi/agent/extensions/teamup.ts`). pi has no stop-blocking, so on `agent_end` it reuses `teamup-hook stop` and injects the unread summary via `pi.sendUserMessage(deliverAs:"followUp")` to re-engage the agent; `session_shutdown` → `teamup-hook session-end`. A dedupe guard prevents an autonomous inject-loop. **Typechecked** against pi's installed types (`@mariozechner/pi-coding-agent` v0.52.12); **not yet runtime-tested** — needs a live pi session (Codex/you) to confirm it fires. [teamup.ln.ts](/pi/agent/extensions/teamup.ln.ts)

### ⚠️ Known edge cases (per project rule #5 — flagged, not yet handled)

- **Non-cooperative loop is avoided**, but the trade-off is the hook only *forces awareness* (recv), not *an answer*. An agent can recv an ask aimed at it and still stop without replying. Stronger "force-answer" blocking was rejected because it can trap a session in a loop. One-line change if we decide we want it.
- **Concurrent join/leave race** on `.sessions.tsv` is "last writer wins"; a lost row only means that session's Stop hook skips one channel (a re-join repairs it). Acceptable at personal-dotfiles scale; not locked.
- **Stale rows** if a session crashes without `session-end`; a re-join in the same cwd overwrites, and `leave` cleans up.

## 🤝 Run 3 — pair-program hardening (opus-claude drives, opus-cc navigates)

Two claude-code sessions on channel `fixteamup`, shared working tree, driver/navigator split. Drove the skill toward "works great". opus-cc gave a final sign-off: seq math + GUID keying + handle guard all sound; residuals are doc-only.

### Bugs found & fixed

| Bug | Root cause | Fix | Found by |
|-----|-----------|-----|----------|
| `asks_for_me` garbage past ~10 msgs | awk compared a for-in **subscript** (pure string) lexically — `"5" > "28"` | `seq+0 > answered_through+0` | opus-cc |
| silent message **drop** on cursor corruption | non-numeric/garbage `.cursor` → `"5" > "abc"` string compare = false → message skipped | `$1 > c+0` coerces cursor numeric | opus-cc found, opus-claude fixed |
| cross-session **mail cross-delivery** | `.sessions.tsv` keyed on cwd alone → two agents in one dir collide | key on **session GUID** (4th col) | opus-claude |
| two agents, **same handle** → cursor race | `.cursor.{handle}` keyed by handle only | `join` refuses a handle held by a different session GUID | opus-cc rec, opus-claude impl |

### The GUID design (answers "one GUID for both harnesses")

`join` stamps the row with `${TEAMUP_SESSION:-${CLAUDE_CODE_SESSION_ID}}`; the hook matches by `.session_id` (else cwd fallback). claude-code sets `CLAUDE_CODE_SESSION_ID` natively; the **pi extension** sets `process.env.TEAMUP_SESSION = sessionManager.getSessionId()` at `session_start` (getShellEnv spreads `process.env`, so bash `join` inherits it). **Verified resume-safe**: pi's `getSessionId()` reads the persisted header id (`sessionId = header?.id ?? randomUUID()`), so it's stable across resume; a new UUID is minted only for a genuinely new session/fork.

### Doc-only residuals (recorded in SKILL.md §6 limitations)

- **idle-wake**: hooks fire at turn-end only; no inbound push wakes a fully idle agent — needs an armed `wait` or a harness API.
- **pi nudge is ignorable by design** (inject, not hard-block) vs claude-code's exit-2 — pi stays the weaker citizen.
- **handle guard**: needs a GUID (GUID-less harness unprotected), not atomic (TOCTOU on simultaneous same-handle join), crashed-session handle reclaim needs same-GUID resume or manual `rm`.

### Still pending for full "works great"

- **pi runtime test** — the extension is typechecked (pi v0.52.12) but never run live; needs a real pi session to confirm `agent_end` fires + the injection re-engages the agent.

## 🟢 Run 4 — idle-wake, join-parse, status (LIVE-validated cross-harness)

The decisive run. Channel `fixteamup`, claude-code (opus-claude driver + opus-cc navigator) + a fresh Codex-on-pi as live test subject.

### Idle-wake — the real product blocker, now FIXED & proven live

David's critique reclassified "idle agent is dead to the channel" from a doc-limitation to a **must-fix** (async/human-out-of-the-loop is the whole point). Fix: the pi extension spawns a **persistent `fs.watch`** at `session_start`; on a channel change with unread it calls `pi.sendUserMessage(...)`, which **starts a turn from cold idle**. Storm-guarded by an event-driven `streaming` flag (`agent_start`/`agent_end`), `lastNudge` dedupe, and 200ms debounce.

opus-cc verified both make-or-break gates against pi's docs (not assumption): **GATE-1** `sendUserMessage` *"when not streaming … triggers a new turn"*; **GATE-2** extensions are long-lived in pi's TUI process + pi itself uses `fs.watch`. **LIVE RESULT: PASS** — a fully idle fresh Codex was woken ~8s after a targeted ask with **no human nudge**, replying with a real `date +%s` + correct member count (channel #51).

### Join-parse misfire — FIXED & proven live

A fresh Codex read `/skill:suss-teamup fixteamup` as *"go fix teamup"* and inspected code instead of joining. Root cause (pi source `formatSkillsForPrompt`): pi shows the agent only **name + description + location** and reads the body on demand — the **frontmatter description is the anchor**, not the body. Fix: lead the description with an imperative ("FIRST action is JOIN; {subject} is a channel NAME not a task; `/suss-teamup fixteamup` = JOIN, not go-fix-teamup"). **LIVE RESULT: PASS** — the next fresh Codex joined correctly (#47).

### Also shipped

- `/suss-teamup status` (no-subject) → my-teams overview + member counts (opus-cc verified PASS).
- `/suss-teamup teardown` documented as an alias for `disconnect all`.
- Handle guard proven live (a second Codex auto-took `dotfiles-wt` because `dotfiles` was held).

### Open follow-up

- **claude-code's own idle-wake half** is NOT solved: whether a Stop-hook-spawned *detached* `wait` actually re-invokes an idle claude-code agent is unverified (every wake so far came from a *tracked* background task). opus-cc going idle mid-session and dropping off the channel demonstrated the gap. Needs its own investigation + a single-instance (pidfile) guard if pursued. **→ RESOLVED in Run 5 below.**

## 🟢 Run 5 — claude-code idle-reachability enforcement (resolves Run 4's open follow-up)

David: *"we need the improvement, claude went to sleep in the channel."* Built by opus-cc on channel `teamup_gastown`, reviewed by opus-claude, live-validated against a fresh Codex on `testcodex`.

### 🔑 Enforce, don't spawn

Run 4's open question is now answered: a Stop hook **cannot** spawn the waker — only an agent-launched `run_in_background` task re-invokes claude-code; a hook-spawned *detached* process can't. So instead of spawning, `teamup-hook stop` **refuses to let a claude-code agent go idle on a channel without a live background `wait`** — perpetual self-arming, enforced, not memory-dependent. When the wait fires (peer spoke) and exits, the next stop re-blocks until re-armed.

- **Opt-in + gated**: condition (b) is behind `--require-listener`. claude-code's Stop wiring passes it; **pi must not** — pi stays reachable via its `fs.watch` watcher and can't run a background wait.
- **Liveness** = the wait's `.wait.{handle}` pidfile + `kill -0` (not a `pgrep` match); `wait` is **single-instance**.

### 🤝 Review (opus-claude) — gastown research + 2 bug fixes folded in

- gastown (Steve Yegge) **doesn't keep agents awake** — ephemeral sessions + a durable ledger + a daemon that *respawns*. Lesson: "respawn from durable state" beats "keep awake." See [learn_gastown_idle.md](/suss-tasks/learn_gastown_idle.md?plain=1#L1).
- **Bug-1**: `pgrep -f` is a substring/regex match → false-positives (prefix handle, regex metachar) → switched to pidfile + `kill -0`.
- **Bug-2**: arm→stop race / double-arm → single-instance guard in `wait`.
- **David's decision: NO tmux** → the churn-free tmux `send-keys` waker is **ruled out** (documented in SKILL.md §6).

### 🐛 Live regression caught & fixed

The new enforcement (live via the symlink) **leaked into pi**: the pi extension's `agent_end → teamup-hook stop` got the unconditional listener-check and told the Codex agent to "run a background wait" — which pi can't do and doesn't need. Gated it off (the opt-in flag); pi is exempt.

### ✅ LIVE RESULT: PASS (fresh Codex on `testcodex`)

- **No background-wait confusion**: pi-agent confirmed it gets only the satisfiable `recv` nudge, never the "arm a wait" one (channel #15).
- **pi idle-wake intact**: woken from cold idle by `fs.watch`, real `date +%s`, no human nudge (#17).
- claude-code enforcement **dogfooded on opus-cc** throughout — the Stop hook repeatedly blocked idle-without-listener, forcing a re-arm. Accepted cost: every peer message = one wake + one re-arm turn.

### 🧱 Boundary (documented in SKILL.md §6)

Idle-wake is solved per-harness **for a LIVE session only** (claude-code = enforced armed-wait; pi = `fs.watch`). Neither resurrects a **dead** session — that needs a gastown-style respawn supervisor (durable ledger + daemon), deliberately out of scope for a no-daemon file channel.

### 🚢 Shipped (committed)

- `32c930a` — idle-reachability enforcement (`teamup-hook` `--require-listener` gate, pidfile + single-instance `wait`, §4/§6 docs).
- `51f4b8f` — `erase`/`cleanup` channel-delete command + the suss-task orientation note (SKILL.md §1a).
- claude-code's local `~/.claude/settings.json` Stop wiring now passes `--require-listener` (local, not version-controlled — same precedent as the original hook wiring).

## 📂 Where the code lives

[teamup script](/claude/skills/suss-teamup.ln/scripts/teamup) and [SKILL.md](/claude/skills/suss-teamup.ln/SKILL.md?plain=1#L1) — **committed** (`371a162` Run-4 feature, `51f4b8f` erase + §1a, `32c930a` Run-5 enforcement).

Key pieces to re-check if behavior regresses:

- [pending_asks_for_me()](/claude/skills/suss-teamup.ln/scripts/teamup#L146) — the implicit-ack rule (targeted ask with no later message from me)
- [latest_peer_seq()](/claude/skills/suss-teamup.ln/scripts/teamup#L139) — default target for `ack`
- [numbered()](/claude/skills/suss-teamup.ln/scripts/teamup#L118) — stamps the stable `#seq` id
- [status command](/claude/skills/suss-teamup.ln/scripts/teamup#L243) — the hook surface (exit 0/1/2, cursor untouched), now consumed by [teamup-hook](/claude/skills/suss-teamup.ln/scripts/teamup-hook)

## 📝 Notes

- 2026-06-24: Phase 1 designed jointly on channel `fixteamup` by `dotfiles-master` (code) + `apper` (design). apper approved implicit-ack over strict `#seq` ack-tracking: in mixed teams that forget things, correctness must not depend on perfect ack syntax — agents answer in prose.
- 2026-06-24: David's field observation — in the live Codex-on-pi-coding-agent + Claude-on-claude-code setup, Codex is the weaker channel citizen: it goes stale and, notably, claims it is "still monitoring the channel" without actually checking. This makes Phase 2 partly a behavioral/trust test, not just a feature test.
- 2026-06-24 (run 2): the asymmetry **holds** (David, watching both sessions): Codex-on-Pi constantly fails to pick up unprompted; claude-code does much better with occasional slips. Claude's one slip was calling `AskUserQuestion` to the human mid-loop instead of running `recv`. Next step is the `Stop`-hook layer for **both** harnesses (Codex-Pi is the priority since it never looks; claude-code still benefits as a safety net for the divert-to-human slip). Building the claude-code half first since that's the harness we control directly here.

## ✅ Closing Note (2026-06-24)

Validated **Phase 2 with real mixed-session behavior** — not Phase 1 only. Across Runs 2–5 the loop ran live with Claude-on-claude-code + fresh Codex-on-pi sessions.

**Cross-harness asymmetry — resolved, not just measured.** The original finding held (Run 2): Codex-on-Pi was the weak citizen — went stale, never picked up unprompted, made hollow "still monitoring" claims; claude-code did better but slipped (diverted to the human, and later went idle with no armed wait). The fix was **per-harness, as predicted**:

- **pi** — a persistent `fs.watch` watcher in the extension wakes a fully idle agent with no re-arm. LIVE PASS (#51, #17).
- **claude-code** — a Stop hook that **enforces** a live armed `wait` (`--require-listener`): the agent can't go idle unreachable. LIVE-dogfooded throughout Run 5.

So both harnesses now wake an idle agent with **no human in the loop**.

**The one thing NOT solved, by design:** neither resurrects a *dead/exited* session — that needs a gastown-style respawn supervisor (durable ledger + daemon), deliberately out of scope for a no-daemon file channel. See [learn_gastown_idle.md](/suss-tasks/learn_gastown_idle.md?plain=1#L1).

Shipped across `371a162`, `51f4b8f`, `32c930a`. Doc-only residuals (handle-guard TOCTOU, GUID-less harness) remain documented in SKILL.md §6 — not blocking.

---
**Created by**: dotfiles-master (2026-06-24)
**Updated by**: opus-claude (2026-06-24), opus-claude + opus-cc pairing (2026-06-24), opus-claude (idle-wake live-validated, 2026-06-24), opus-cc (Run 5 — claude-code idle-reachability enforcement, 2026-06-24)
