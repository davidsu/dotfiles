import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import { readFileSync, statSync } from "node:fs"
import { join } from "node:path"

type LocalContext = {
	content: string
	mtimeMs: number
}

const localContextPath = (cwd: string) => join(cwd, "CLAUDE.local.md")

const readLocalContext = (path: string): LocalContext | null => {
	try {
		const { mtimeMs } = statSync(path)
		return { content: readFileSync(path, "utf-8"), mtimeMs }
	} catch {
		return null
	}
}

export default function (pi: ExtensionAPI) {
	const cache = new Map<string, LocalContext>()

	pi.on("before_agent_start", async (event, ctx) => {
		const path = localContextPath(ctx.cwd)
		const cached = cache.get(path)
		const current = readLocalContext(path)
		if (!current) {
			cache.delete(path)
			return
		}
		if (cached && cached.mtimeMs === current.mtimeMs) {
			return {
				systemPrompt: `${event.systemPrompt}\n\nLocal repository override from ${path}:\n\n${cached.content}`,
			}
		}
		cache.set(path, current)
		return {
			systemPrompt: `${event.systemPrompt}\n\nLocal repository override from ${path}:\n\n${current.content}`,
		}
	})
}
