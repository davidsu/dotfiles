/**
 * Claude Code-style footer for pi
 *
 * Replicates the Claude Code statusline format:
 *   Opus 4.6 | Context: 35.0% | ../projects/apper | (platform-jwt-refresh-token)
 *   ▶▶ bypass permissions on (shift+tab to cycle) · PR #4321
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import * as path from "node:path";

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					// Model name - format like "Opus 4.6"
					const modelId = ctx.model?.id ?? "no-model";
					const modelName = formatModelName(modelId);

					// Context usage
					const usage = ctx.getContextUsage();
					const contextPct = usage
						? `${((usage.tokens / usage.contextWindow) * 100).toFixed(1)}%`
						: "0.0%";

					// Short path (relative to home)
					const cwd = ctx.cwd;
					const home = process.env.HOME || "";
					const shortPath = home && cwd.startsWith(home) ? "~" + cwd.slice(home.length) : cwd;
					// Show parent/current like Claude Code does
					const displayPath = shortenPath(shortPath);

					// Git branch
					const branch = footerData.getGitBranch();
					const branchStr = branch ? `(${branch})` : "";

					// Extension statuses (for permission mode, etc.)
					const statuses = footerData.getExtensionStatuses();
					const statusLine = statuses.length > 0 ? statuses.join(" · ") : "";

					// Colors matching Claude Code's statusline.sh exactly:
					// Model: #82d2c3 (teal), Context: #c3a0d2 (lavender), Path: ANSI 90 (dark grey)
					// Branch: bold blue (#5f87ff), Separators: dark grey
					const teal = "\x1b[38;2;130;210;195m";
					const lavender = "\x1b[38;2;195;160;210m";
					const grey = "\x1b[90m";
					const boldBlue = "\x1b[1;34m";
					const reset = "\x1b[0m";
					const sep = `${grey} | ${reset}`;

					let line1 = `${teal}${modelName}${reset}${sep}${lavender}Context: ${contextPct}${reset}${sep}${grey}${displayPath}${reset}`;
					if (branchStr) {
						line1 += `${sep}${boldBlue}${branchStr}${reset}`;
					}

					// Build line 2: statuses if any
					const lines: string[] = [truncateToWidth(line1, width)];
					if (statusLine) {
						lines.push(truncateToWidth(theme.fg("dim", statusLine), width));
					}

					return lines;
				},
			};
		});
	});
}

function formatModelName(modelId: string): string {
	// Turn "claude-opus-4-6" -> "Opus 4.6", "claude-sonnet-4-20250514" -> "Sonnet 4"
	const id = modelId.toLowerCase();

	if (id.includes("opus")) {
		const ver = extractVersion(id, "opus");
		return `Opus ${ver}`;
	}
	if (id.includes("sonnet")) {
		const ver = extractVersion(id, "sonnet");
		return `Sonnet ${ver}`;
	}
	if (id.includes("haiku")) {
		const ver = extractVersion(id, "haiku");
		return `Haiku ${ver}`;
	}
	// Fallback for non-Anthropic models
	return modelId;
}

function extractVersion(id: string, family: string): string {
	// Match patterns like "opus-4-6" -> "4.6", "sonnet-4-20250514" -> "4"
	const regex = new RegExp(`${family}-?(\\d+)(?:-(\\d+))?`);
	const match = id.match(regex);
	if (!match) return "";
	const major = match[1];
	const minor = match[2];
	// If minor looks like a date (6+ digits), skip it
	if (minor && minor.length < 4) {
		return `${major}.${minor}`;
	}
	return major;
}

function shortenPath(fullPath: string): string {
	// Show like "../projects/apper" style
	const parts = fullPath.split("/");
	if (parts.length <= 3) return fullPath;
	return ".." + "/" + parts.slice(-2).join("/");
}
