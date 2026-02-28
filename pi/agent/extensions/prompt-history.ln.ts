/**
 * Global prompt history search extension.
 *
 * `/history` opens fzf with all prompts from all pi sessions.
 * Selecting a prompt pastes it into the editor.
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent"
import { spawnSync } from "node:child_process"
import { readdir, readFile } from "node:fs/promises"
import { join } from "node:path"

interface PromptEntry {
	text: string
	timestamp: string
	project: string
}

const SESSIONS_DIR = join(process.env.HOME ?? "~", ".pi", "agent", "sessions")

const prettifyProject = (dir: string) =>
	dir.replace(/^--/, "/").replace(/--/g, "/").replace(/^\/Users\/[^/]+/, "~")

const formatTimestamp = (ts: string) => {
	if (!ts) return ""
	const d = new Date(ts)
	const pad = (n: number) => String(n).padStart(2, "0")
	return `${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

const toOneLiner = (text: string) =>
	text.replace(/\n/g, " ↵ ").replace(/\t/g, " ")

async function extractUserPrompts(filePath: string, project: string) {
	const content = await readFile(filePath, "utf-8")
	const prompts: PromptEntry[] = []

	for (const line of content.split("\n")) {
		if (!line.trim()) continue
		const entry = JSON.parse(line)
		if (entry?.message?.role !== "user") continue

		const text = (entry.message.content ?? [])
			.filter((p: { type: string }) => p.type === "text")
			.map((p: { text: string }) => p.text)
			.join("\n")
			.trim()

		if (text) {
			prompts.push({ text, timestamp: entry.timestamp ?? "", project })
		}
	}

	return prompts
}

async function loadAllPrompts() {
	const prompts: PromptEntry[] = []

	let projectDirs: string[]
	try { projectDirs = await readdir(SESSIONS_DIR) } catch { return prompts }

	for (const projectDir of projectDirs) {
		const project = prettifyProject(projectDir)
		let sessionFiles: string[]
		try { sessionFiles = await readdir(join(SESSIONS_DIR, projectDir)) } catch { continue }

		for (const file of sessionFiles) {
			if (!file.endsWith(".jsonl")) continue
			try {
				prompts.push(...await extractUserPrompts(join(SESSIONS_DIR, projectDir, file), project))
			} catch { /* skip malformed sessions */ }
		}
	}

	const seen = new Map<string, PromptEntry>()
	for (const p of prompts) {
		const existing = seen.get(p.text)
		if (!existing || p.timestamp > existing.timestamp) seen.set(p.text, p)
	}

	return [...seen.values()].sort((a, b) => b.timestamp.localeCompare(a.timestamp))
}

/** NUL-separated line for fzf: "timestamp\tprompt_oneliner" */
const toFzfLine = (p: PromptEntry) =>
	`${formatTimestamp(p.timestamp)}\t${toOneLiner(p.text)}`

async function showHistorySearch(ctx: ExtensionContext) {
	if (!ctx.hasUI) {
		ctx.ui.notify("prompt-history requires interactive mode", "error")
		return
	}

	const prompts = await loadAllPrompts()
	if (prompts.length === 0) {
		ctx.ui.notify("No prompt history found", "info")
		return
	}

	// Build fzf input: NUL-delimited so newlines in prompts don't break it
	const fzfInput = prompts.map(toFzfLine).join("\n")

	// Build a lookup from fzf display line → original prompt text
	const lineToPrompt = new Map<string, PromptEntry>()
	for (const p of prompts) {
		lineToPrompt.set(toFzfLine(p), p)
	}

	const selected = await ctx.ui.custom<string | null>((tui, _theme, _kb, done) => {
		// We'll stop the TUI, run fzf, then restart
		// Return a dummy component; the real work happens in setTimeout(0) to let custom() set up
		setTimeout(() => {
			tui.stop()

			const result = spawnSync("fzf", [
				"--scheme=history",
				"--no-sort",
				"--ansi",
				"--height=100%",
				"--layout=reverse",
				"--prompt=Search: ",
				"--preview-window=up:40%:wrap",
				"--preview=echo {2..}",
				"--delimiter=\t",
				"--with-nth=1..",
				"--nth=2..",
				"--header=Prompt History",
				"--color=header:bold",
			], {
				input: fzfInput,
				stdio: ["pipe", "pipe", "inherit"],
				encoding: "utf-8",
				env: { ...process.env, FZF_DEFAULT_OPTS: "" },
			})

			// Restart TUI
			tui.start()
			tui.terminal.clearScreen()
			tui.requestRender(true)

			const output = (result.stdout ?? "").trim()
			if (result.status !== 0 || !output) {
				done(null)
				return
			}

			// Match selected line back to prompt
			const match = lineToPrompt.get(output)
			done(match?.text ?? null)
		}, 0)

		// Dummy component that renders nothing while fzf runs
		return {
			render: () => [],
			invalidate: () => {},
			handleInput: () => {},
		}
	})

	if (selected === null) return
	ctx.ui.setEditorText(selected)
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("history", {
		description: "Search prompt history across all sessions",
		handler: async (_args, ctx) => { await showHistorySearch(ctx) },
	})
}
