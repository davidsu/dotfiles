closed
# How Gas Town (Steve Yegge) does message-passing + avoids idle agents

## Summary

Research into `/Users/davidsu/Developer/gastown` (Steve Yegge's Go multi-agent orchestrator) for the suss-teamup idle-wake work. **Key lesson: Gas Town does NOT keep an idle agent alive — it makes agents ephemeral and respawns them from durable state.** That's the opposite of our "wake the sleeping interactive agent" approach (fs.watch / armed wait).

## 📨 Message passing — two transports

| Transport | Use | Mechanism |
|-----------|-----|-----------|
| **`gt mail`** | async, cross-agent, survives crashes | routed by address (`<rig>/witness`, `<rig>/refinery`, `mayor/`); persisted as durable Dolt ledger entries — observable + audit trail; lifecycle read→process→delete. Router in [internal/mail/router.go](/internal/mail/router.go) |
| **`gt nudge`** | inject into a **live** session | **tmux send-keys** into the agent's pane ([internal/cmd/nudge.go](/internal/cmd/nudge.go), [internal/tmux/tmux.go](/internal/tmux/tmux.go)); `immediate` mode interrupts in-flight work. ACP agents have no pane → different transport. |

Patrol agents consume mail by checking their inbox each patrol cycle (FCFS). Message protocol = subject patterns (`POLECAT_DONE`, `LIFECYCLE:Cycle`, `MERGE_READY`, `HELP:`…) in `internal/witness/protocol.go`.

## 💤 How it avoids idle agents — it doesn't; it respawns

**The reframe:** there is no "idle interactive agent waiting for a message." Agents (**polecats**) are **ephemeral, session-per-step** — *"sessions are pistons; sandboxes are cylinders."* A session does one step and **exits**. When work finishes/idles, the **session terminates**.

State lives **outside** the agent, so a fresh session can resume:
- **Dolt ledger** — molecule/step progress
- **git** — branch + worktree (the persistent "sandbox")
- **the hook** — pins the work to the agent identity

**Wake = supervisor respawns a fresh session.** A **daemon** (3-min heartbeat tick) + **witness** (per-rig patrol) detect a dead session that still has pinned work and call `SessionManager.Start()` → new tmux session in the existing worktree → `SessionStart` hook fires `gt prime --hook` → the new session discovers its next step from the durable ledger.

**Liveness signals** feed the supervisor: agents self-report a [heartbeat](/internal/polecat/heartbeat.go) (`working`/`idle`/`exiting`/`stuck` + timestamp) and touch a [keepalive](/internal/keepalive/keepalive.go) file; the daemon infers staleness by file age (3-min threshold) with exponential backoff.

**The completion guarantee (GUPP):** as long as (1) work is pinned, (2) the sandbox persists, and (3) a supervisor keeps respawning sessions, the molecule WILL complete — regardless of idle/crash. Redundant patrol (Daemon / Deacon / Witness / Refinery) means if one monitor dies another detects the degraded state. Principle: **"discover, don't track"** — re-derive state from observables (ledger/git/tmux), self-heal next cycle.

## 🎯 Why this matters for suss-teamup

We've been solving "wake a long-lived idle interactive agent" (pi `fs.watch` → `sendUserMessage`; claude-code armed `wait`). Gas Town sidesteps that entirely: **persist state externally + let the agent die + have a supervisor respawn it from the durable state when work is pending.** The `gt nudge` (tmux send-keys) path is the closest analog to our inject-into-live-session, but the durable mechanism is respawn, not keep-alive.

Tradeoff: respawn needs a real persistent store + a running supervisor daemon + tmux/process control — heavier than our file-channel + hooks, but crash-proof and genuinely human-out-of-the-loop at scale (20-30 agents).

## ⛔ Decision (David, 2026-06-24): no tmux

The gastown-style churn-free idle-wake for claude-code — one external `tmux send-keys` watcher per channel injecting terminal input into a live session — was considered and **ruled out: no tmux dependency.** claude-code therefore stays on the **enforce-armed-wait** model (Stop hook `--require-listener` blocks until the agent has a live background `wait`; recv-to-clear-then-arm to avoid instant-fire churn). pi stays on the always-on `fs.watch` watcher. The tmux/respawn-supervisor approach is recorded here as prior art only — not a planned path.

---
**Created by**: opus-claude (2026-06-24)
