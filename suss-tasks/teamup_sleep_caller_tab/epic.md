closed
# 💤 teamup-sleep: the caller's own claude dies seconds after it sleeps a peer

## Summary

On 2026-10-14 08:22Z lead.protected.main ran `teamup-sleep native.publish` from a background
retry loop; the sleeper's tab closed, and 6 s later the caller's own claude session ended too.
Find the mechanism with evidence, fix it in the suss-teamup skill, prove it with throwaway agents.

## 🧾 Evidence

| When (UTC)   | What                                                                               |
|--------------|------------------------------------------------------------------------------------|
| 08:21:36     | caller starts the background loop: `sleep 25; teamup-sleep native.publish` (x6)    |
| 08:22:05     | loop prints `closed the tab of native.publish`; `leave --all` parks native.publish |
| 08:22:05.85  | native.publish is still alive: its listener-ended notice starts a new turn         |
| 08:22:10     | caller runs `teamup-wake --asleep native.publish`: exit 1 (session still running)  |
| 08:22:11.37  | native.publish's Bash tool is SIGKILLed (exit 137): its claude is tearing down     |
| 08:22:11.665 | caller's claude tears down (its two listeners marked `killed`), parks at 08:22:12  |

Transcripts: the caller and sleeper session `.jsonl` files on the laptop (paths kept in the private copy).

### ⏱️ iTerm's close is not a kill

Measured on throwaway tabs (2026-10-14 08:43Z, three runs): the AppleScript `close` that
`teamup-sleep` uses returns at once, but the tab's process gets SIGHUP only 5.2 to 5.3 s later.
That is iTerm's per-profile "Undo can revive a session that has been closed for up to X seconds"
(default 5 s): the shell is not terminated until the undo window passes
(https://iterm2.com/3.5/documentation-preferences-profiles-session.html). The neighbour tab, a
tab spawned `--after` the anchor, and the focused tab all survived.

Consequences already proven:

- `teamup-sleep` prints `closed the tab of X` while X is still running for ~5 s
- `teamup-wake --asleep X` right after a sleep answers "still running" (the caller hit this)
- the sleeping agent's armed `wait` exits on `leave`, so the agent wakes and runs one more turn
  inside the undo window

### ❌ Ruled out

- 07:40Z (lead.21): nine agents left in the same second, that was the iTerm quit
- 07:50Z (lead.channel): died idle with no agent closing anything (David at the keyboard)
- a second `teamup-sleep` or any session-closing tool call by any agent in 08:21:55-08:22:13Z:
  none in any transcript under `~/.claude/projects`

## 🔬 Repro (2026-10-14 08:54-08:57Z)

Throwaway channel `sleep_repro`: a haiku stand-in caller (`repro.caller2`) spawned a haiku worker
with `teamup-spawn` (so the worker's tab sat right of the caller's, as in the incident) and ran
the identical background loop. The worker left at 08:55:44Z and its process ended; the caller
stayed alive and reported so at 08:56:55Z. **The fan-out did not reproduce.** The mechanism that
ended lead.protected.main 0.3 s after native.publish is therefore still unproven; nothing records
what had keyboard focus at 08:22:06Z, and David was typing into lead.22's tab at 08:21:57Z and
08:22:39Z.

## ✅ Fix

Commit `40965c0` on dotfiles master, `claude/skills/suss-teamup.ln/scripts/teamup-sleep`:

- the agent's claude is hung up **by pid** first (`SIGHUP`, what a tab close delivers; the
  session exits through its SessionEnd hooks, which `leave` and park it)
- the script waits for the process to exit (20 s cap), then `leave`s whatever is left and closes
  the tab, found by **tty** (the title no longer reads `<handle> (claude)` once claude exited)
- the kill target is now explicit, no longer iTerm's undo-timer bookkeeping

Proof on the two throwaway haiku agents: `stopped repro.caller (claude pid 44409)` in 2.3 s, pid
gone, parked record written by its own hook, tab closed, `teamup-wake --asleep` answers 0 at once,
the calling session survived. Test: `tests/sleep_stop_test.sh` (4 checks, passing);
`tests/sleep_guard_test.sh` still passes. Doc: `resources/agent_lifecycle.md` step 3.

## 📝 Notes

- 2026-10-14: `teamup-sleep --force` on a busy agent now ends it mid-turn by SIGHUP, same as a
  tab close did after the undo window, only without the 5 s of extra life
- 2026-10-14 09:58Z regression (David, screenshot via lead.22): after 40965c0 every agent that slept
  ITSELF left its tab open as a bare shell. `/suss-teamup sleep` runs `teamup-sleep --force` on the
  agent itself, so the script was a child of the claude it hung up and died before the tab close.
  Fixed in `6a867b7`: when the target is an ancestor, stop + leave + close run in their own process
  group (`bash -m`, `nohup`). Proof: throwaway `self.sleeper` parked itself at 10:00:27Z, process and
  tab gone; peer sleep from another session still closes (`peer.sleeper`). Three leftover shell
  tabs (ttys002/003/009) closed by hand.

## 🗃️ parked.tsv wiped (2026-10-14, found by lead.protected.main 12:10Z)

`~/.local/state/suss-teamup/parked.tsv` started at the 10:00:27Z self-sleep probe; every older row
was gone, so `teamup-wake` could not resume the night's agents.

**Cause (code):** every rewrite of `.sessions.tsv` and `parked.tsv` in `scripts/teamup` was
`awk FILE > FILE.tmp && mv FILE.tmp FILE`: one shared temp name, no lock. Two concurrent leaves
(an agent's SessionEnd hook and a sleep script, or two hooks) let the second awk read the freshly
truncated temp inode right after the first `mv`, and the file collapsed to the one row appended
next. The race predates today's fixes: at 08:35Z the file already held a half-written `0:20Z` row.

**Fix:** commit `8b51a82` on dotfiles master: all six rewrite sites go through `rewrite_tsv`
(private `mktemp` beside the file) under `with_tsv_lock` (mkdir lock, stale after 5 s).
`tests/registry_race_test.sh` leaves 20 handles at once: 2/20 parked rows survived on the old
script, 20/20 now.

**Repair:** backup `parked.tsv.bak_sleep.tab.bug_1520`; 16 rows restored from my 08:35Z snapshot of
the file plus transcripts and channel logs for `teamup.focus` and `bridge.handle`. Wakeable again
(transcript on disk): b44sync.mcp, bridge.handle, browser.skill.0, dotfiles.laptop, lead.19,
lead.20, machine.lead, shahar.reply, teamup.focus, whatsapp.route. Rows kept but NOT wakeable, no
transcript exists for their session id anywhere under `~/.claude/projects`: troubleshoot.david.away,
away.skill, box.attach, slack.bridge, tanstack.link, lead.21. native.sheet is running, so no row.

## ✅ Closing Note

Three defects fixed on dotfiles master: `40965c0` (stop the agent by pid before closing its tab),
`6a867b7` (self-sleep finishes detached), `8b51a82` (locked, private-temp rewrites of the registry
and parked.tsv). parked.tsv repaired, 10 handles wakeable again. Open question left as is: what
ended lead.protected.main 0.3 s after native.publish at 08:22Z; the faithful repro did not show it.

---
**Created by**: sleep.tab.bug (2026-10-14)
**Updated by**: sleep.tab.bug (2026-10-14), sleep.tab.bug (2026-10-14 regression), sleep.tab.bug (2026-10-14 parked.tsv wipe)
