/**
 * teamup — keep a pi agent live on its teamup channels, even while idle.
 *
 * The core promise of agent-to-agent coordination is async / human-out-of-the-loop:
 * a peer's message must be able to START a turn on an idle agent with no human
 * nudge and nothing for the agent to remember to arm. `agent_end` alone can't do
 * that — a fully idle agent never ends a turn. So at session_start we spawn a
 * PERSISTENT file watcher on the teamup dir; the instant a channel changes and
 * this session has unread, we `pi.sendUserMessage(...)`, which always triggers a
 * turn (waking an idle agent). `agent_end` stays as a belt-and-suspenders check
 * for unread that piled up during a turn. Torn down at session_shutdown.
 *
 * Session identity: pi gives the bash `teamup join` no session-id env, so at
 * session_start we bridge pi's GUID (stable across resume — read from the session
 * header) into TEAMUP_SESSION; getShellEnv() spreads process.env into every bash
 * tool call, so `join` stamps the registry row with it and the hook keys by GUID.
 *
 * Reuses the harness-neutral `teamup-hook`: it reads `.cwd`/`.session_id` on stdin
 * and, for `stop`, exits 2 with the unread summary on stderr.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import { spawnSync } from "node:child_process"
import { mkdirSync, watch, type FSWatcher } from "node:fs"
import { join } from "node:path"

const HOOK = join(process.env.HOME ?? "~", ".claude/skills/suss-teamup/scripts/teamup-hook")
const BASE = process.env.SUSS_TEAMUP_DIR ?? "/tmp/suss-teamup"

const unreadSummary = (cwd: string, sessionId: string): string => {
	const result = spawnSync(HOOK, ["stop"], {
		input: JSON.stringify({ cwd, session_id: sessionId }),
		encoding: "utf-8",
	})
	return result.status === 2 ? (result.stderr ?? "").trim() : ""
}

export default function (pi: ExtensionAPI) {
	let lastNudge = ""
	let streaming = false
	let watcher: FSWatcher | undefined
	let debounce: ReturnType<typeof setTimeout> | undefined

	// Surface unread into the agent's context, starting a turn if it's idle.
	// Re-push only when the unread state changed, so an ignored nudge can't loop.
	const surface = (cwd: string, sessionId: string) => {
		const nudge = unreadSummary(cwd, sessionId)
		if (!nudge) {
			lastNudge = ""
			return
		}
		if (nudge === lastNudge) return
		lastNudge = nudge
		pi.sendUserMessage(nudge, { deliverAs: "followUp" })
	}

	pi.on("session_start", async (_event, ctx) => {
		const cwd = ctx.cwd
		const sessionId = ctx.sessionManager.getSessionId()
		process.env.TEAMUP_SESSION = sessionId
		try {
			mkdirSync(BASE, { recursive: true })
			watcher = watch(BASE, { recursive: true }, () => {
				// Debounce: fs.watch double-fires per write (rename+change). Only wake
				// when idle — a mid-turn change is the agent's own work, and agent_end
				// owns turn-end; this watcher exists solely to wake a COLD-IDLE agent.
				clearTimeout(debounce)
				debounce = setTimeout(() => {
					if (!streaming) surface(cwd, sessionId)
				}, 200)
			})
		} catch {
			// No watcher (e.g. recursive watch unsupported) — agent_end still covers turn-end.
		}
	})

	pi.on("agent_start", async () => {
		streaming = true
	})

	pi.on("agent_end", async (_event, ctx) => {
		streaming = false
		surface(ctx.cwd, ctx.sessionManager.getSessionId())
	})

	pi.on("session_shutdown", async (_event, ctx) => {
		watcher?.close()
		clearTimeout(debounce)
		spawnSync(HOOK, ["session-end"], {
			input: JSON.stringify({ cwd: ctx.cwd, session_id: ctx.sessionManager.getSessionId() }),
			encoding: "utf-8",
		})
	})
}
