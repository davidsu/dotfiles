/**
 * Global prompt history search extension.
 *
 * `/history` opens a search overlay across ALL pi sessions.
 * Selecting a prompt pastes it into the editor.
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent"
import { DynamicBorder } from "@mariozechner/pi-coding-agent"
import {
	Container, Input, type SelectItem, SelectList, Text,
	matchesKey, Key, type Component, type Focusable,
} from "@mariozechner/pi-tui"
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
	text.replace(/\n/g, " ↵ ")

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

/** Case-insensitive substring match on the prompt text */
const matchesFilter = (prompt: PromptEntry, filter: string) =>
	prompt.text.toLowerCase().includes(filter.toLowerCase())

/**
 * Build SelectItems with metadata in label (capped at 30 by SelectList)
 * and prompt text in description (gets remaining terminal width).
 */
const toSelectItems = (prompts: PromptEntry[]): SelectItem[] =>
	prompts.map((p) => ({
		value: p.text,
		label: `${formatTimestamp(p.timestamp)}  ${p.project}`,
		description: toOneLiner(p.text),
	}))

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

	const selectListTheme = {
		selectedPrefix: (t: string) => t,
		selectedText: (t: string) => t,
		description: (t: string) => t,
		scrollInfo: (t: string) => t,
		noMatch: (t: string) => t,
	}

	const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
		const container = new Container()

		container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)))
		container.addChild(new Text(
			theme.fg("accent", theme.bold(" Prompt History")) +
			theme.fg("dim", `  (${prompts.length} prompts)`), 1, 0,
		))

		const searchInput = new Input()
		const inputWrapper = new Container()
		inputWrapper.addChild(new Text(theme.fg("dim", " Search:"), 1, 0))
		inputWrapper.addChild(searchInput)
		container.addChild(inputWrapper)

		// Theming applied via wrapper since we rebuild SelectList on filter
		selectListTheme.selectedPrefix = (t: string) => theme.fg("accent", t)
		selectListTheme.selectedText = (t: string) => theme.fg("accent", t)
		selectListTheme.description = (t: string) => theme.fg("muted", t)
		selectListTheme.scrollInfo = (t: string) => theme.fg("dim", t)
		selectListTheme.noMatch = (t: string) => theme.fg("warning", t)

		let currentPrompts = prompts
		let selectList = new SelectList(
			toSelectItems(currentPrompts),
			Math.min(currentPrompts.length, 20),
			selectListTheme,
		)
		selectList.onSelect = (item) => done(item.value)
		selectList.onCancel = () => done(null)

		const selectListContainer = new Container()
		selectListContainer.addChild(selectList)
		container.addChild(selectListContainer)

		container.addChild(new Text(
			theme.fg("dim", " ↑↓ navigate • enter select • esc cancel • type to filter"), 1, 0,
		))
		container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)))

		const rebuildList = (filter: string) => {
			currentPrompts = filter
				? prompts.filter((p) => matchesFilter(p, filter))
				: prompts
			selectList = new SelectList(
				toSelectItems(currentPrompts),
				Math.min(currentPrompts.length, 20),
				selectListTheme,
			)
			selectList.onSelect = (item) => done(item.value)
			selectList.onCancel = () => done(null)
			selectListContainer.clear()
			selectListContainer.addChild(selectList)
		}

		const isNavKey = (data: string) =>
			matchesKey(data, Key.up) || matchesKey(data, Key.down) ||
			matchesKey(data, Key.ctrl("n")) || matchesKey(data, Key.ctrl("p"))

		const comp: Component & Focusable = {
			focused: false,

			render(width) {
				searchInput.focused = this.focused
				return container.render(width)
			},

			invalidate: () => container.invalidate(),

			handleInput(data) {
				if (matchesKey(data, Key.escape)) { done(null); return }
				if (matchesKey(data, Key.enter)) {
					const selected = selectList.getSelectedItem()
					if (selected) done(selected.value)
					return
				}
				if (isNavKey(data)) {
					selectList.handleInput(data)
				} else {
					searchInput.handleInput(data)
					rebuildList(searchInput.getValue())
				}
				tui.requestRender()
			},
		}

		return comp
	})

	if (result === null) return
	ctx.ui.setEditorText(result)
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("history", {
		description: "Search prompt history across all sessions",
		handler: async (_args, ctx) => { await showHistorySearch(ctx) },
	})
}
