# Lifecycle hooks and the statusline (per harness)

`recv` at checkpoints (resources/mailbox.md) and a background `wait` (resources/listening.md) are best-effort: an agent
that goes heads-down still forgets. The durable fix is a harness **Stop hook** so
an agent literally cannot end its turn while peer messages sit unread.
`scripts/teamup-hook` provides this, harness-neutrally:

- `join`/`leave` persist a `cwd → (subject, handle, session_guid)` map in
  `$SUSS_TEAMUP_DIR/.sessions.tsv`. The **session GUID** is the key — it's
  collision-free even when several agents share a cwd (the original "two agents in
  one dir cross-deliver each other's mail" bug). `join` reads the GUID from
  `$TEAMUP_SESSION` (set by a harness wrapper, e.g. the pi extension) or
  `$CLAUDE_CODE_SESSION_ID` (native to claude-code); if neither is set the row's
  GUID is empty and the hook falls back to cwd matching.
- `teamup-hook stop` reads `.session_id` (and `.cwd`) from the hook event JSON on
  stdin, finds this session's channels (by GUID, else cwd), and **exits 2 to block
  the stop** while any channel (a) has unread messages [`recv` clears] or, with
  **`--require-listener`** (claude-code only), (b) has no live background `wait`
  listener [arm one to clear; liveness = the wait's `.wait.{handle}` pidfile +
  `kill -0`]. Both clear on the agent's next action, so it can't loop; fails open
  (exit 0) on any missing input or tool error. **(b) is opt-in** because it assumes
  the agent can launch a persistent background `wait` — pi must NOT pass the flag
  (it stays reachable via `fs.watch`, not a `wait` process).
- `teamup-hook stop` also blocks **once** when your session name and your channel
  handle disagree (the user `/rename`d you mid-flight), telling you the exact
  `teamup rename` to run. Once-only, keyed on the new name: `rename` can legitimately
  refuse (a live peer holds that name), and a block you can't clear would wedge the
  session. A *further* rename nudges again. **Exception:** if the session name is
  itself a channel name it's a pre-fix spawn (spawn used to pass `--name {subject}`),
  not a user rename — re-keying there would hand you a channel-shaped handle and
  orphan every message that named the old one, so the nudge instead asks you to get
  the *user* to `/rename` the session to your handle.
- `teamup-hook session-end` auto-`leave`s this session's channels so rosters stay honest.
- `join` also **refuses a handle already held by a different session** (cursor
  files are keyed by handle, so two live sessions sharing one would race it).

**claude-code wiring** (`~/.claude/settings.json`):

```json
"hooks": {
  "Stop":       [{ "hooks": [{ "type": "command", "command": "~/.claude/skills/suss-teamup/scripts/teamup-hook stop --require-listener", "timeout": 10 }] }],
  "SessionEnd": [{ "hooks": [{ "type": "command", "command": "~/.claude/skills/suss-teamup/scripts/teamup-hook session-end", "timeout": 10 }] }]
}
```

**pi (pi-coding-agent):** the extension `~/.pi/agent/extensions/teamup.ts` (from
`pi/agent/extensions/teamup.ln.ts`) wires this in. At `session_start` it sets
`process.env.TEAMUP_SESSION = sessionManager.getSessionId()` so the bash `join`
inherits pi's session GUID (pi gives bash no session-id env of its own; the GUID
is stable across resume — it's read from the persisted session header). The same
bridge carries **identity**: `TEAMUP_SESSION_NAME` (from `pi.getSessionName()`, which
`/banner` sets — refreshed every `agent_start`, since pi rebuilds the bash env per
command, so a mid-session `/banner` lands on the next turn) and
`TEAMUP_NAME_COMMAND=/banner`, which is what `teamup name-command` reports. That makes
`handle == the name on screen` true on pi too: an unnamed pi session reports no name at
all, so derivation stays empty rather than inventing one. pi can't
block a stop, so on `agent_end` it runs `teamup-hook stop` with `{cwd, session_id}`
and, on exit 2, injects the unread summary via
`pi.sendUserMessage(..., {deliverAs:"followUp"})` so the agent handles it before
going idle; `session_shutdown` runs `teamup-hook session-end`. A dedupe guard
avoids re-injecting an unchanged nudge (no autonomous loop). For **idle wake** pi
also runs a persistent `fs.watch` on the channel dir (armed at `session_start`,
torn down at `session_shutdown`): on a change with unread it `sendUserMessage`s to
wake even a fully idle pi agent — so pi needs no armed `wait` and calls `teamup-hook
stop` **without `--require-listener`**. Because the watcher owns the wake, the
extension also **blocks** any bash `tool_call` that arms an idle listener
(`teamup wait … --timeout 0`) with the resources/listening.md pi rule: agents kept re-arming a listener
that does nothing here, then looping around it. **Any other harness** reuses `teamup-hook`
the same way: expose the session GUID as `$TEAMUP_SESSION` for `join`, pass
`.session_id` (+ `.cwd`) to the hook on stdin, and pass `--require-listener` only if
its agent can hold a persistent background `wait`.

**codex (Codex CLI):** codex needs **no wrapper extension** — it natively does what
the other harnesses bolt on. `join` reads the GUID from `$CODEX_THREAD_ID`, which
codex exports into the agent's shell; codex's `Stop` hook event carries the **same**
value as `.session_id`, so GUID routing matches end-to-end (verified). Codex honors a
`Stop` hook that exits 2 — it blocks the turn-end and re-invokes the agent with the
hook's stderr, exactly like claude-code. Wiring is `codex/hooks.ln.json` →
`~/.codex/hooks.json` (the hooks feature, `[features].hooks`, is **on by default** —
no flag needed); it runs `teamup-hook stop` **without `--require-listener`**. Codex
limitations: (1) **no idle-wake** — its exec harness doesn't keep a backgrounded
`wait` alive and doesn't auto-start a turn when a bg process exits, so a peer message
can't wake a *fully idle* codex (the Stop hook only catches unread that piled up
*during* a live turn). (2) **no `SessionEnd` event** — no auto-`leave`, so a codex
roster entry goes stale on exit (channels are ephemeral, so it self-heals on reboot).
(3) **the hook is global** — `~/.codex/hooks.json` fires `teamup-hook` on *every*
codex session; that's fine because `teamup-hook` fail-opens (exits 0) for any session
not on a channel. (4) codex loads hooks **at session start**, so a codex already
running when the hook was installed won't have it until restarted.

### Joined-teams statusline

`teamup teams --session {guid}` prints this session's joined channels as one compact
line (markers: `!` = an ask aimed at you, `*` = unread), or nothing when on no teams.
The claude statusline (`claude/statusline.ln.sh`) and the pi footer
(`pi/agent/extensions/claude-code-footer.ln.ts`) both call it and render an `⇄ …`
segment. Codex has **no** custom-command statusline (its `/statusline` only toggles
built-in items; openai/codex#20244 tracks one), so it shows no teams segment — the
Stop-hook unread surfacing is its equivalent signal.
