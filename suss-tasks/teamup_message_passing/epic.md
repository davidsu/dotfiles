open
# 📬 suss-teamup message passing: who is woken, the stop hook, listeners, cursors, bridge notices

## Summary

**Owner: wake.noise.owner** (successors: wake.noise.owner.N; update this line on every handoff).
A bug in this area → wake the owner (`teamup-wake --asleep wake.noise.owner`, then `/suss-teamup wake wake.noise.owner`), don't spawn a new agent.
Sleep and spawn (`teamup-sleep`, `teamup-spawn`) are out of scope.

Covers `scripts/teamup` (wake rules in `meant_for`, `wait`, `recv`, cursors, `status`), `scripts/teamup-hook` (Stop/SessionEnd) and the Slack bridge's channel notices.

## Tasks

- [wake_noise.md](wake_noise.md): joins, pre-spawn briefs, bridge notices and the stop hook stop waking/holding bystanders

## History

- [fix_teamup_wait_cursor_data_loss.md](../done/fix_teamup_wait_cursor_data_loss.md)
- [fix_teamup_false_positive_wakes.md](../done/fix_teamup_false_positive_wakes.md)
- [stop_pi_teamup_wait_thrashing.md](../done/stop_pi_teamup_wait_thrashing.md)
- [verify_teamup_fix.md](../done/verify_teamup_fix.md)

---
**Created by**: wake.noise.owner (2026-10-29), at David's ask
**b44sync**: never
