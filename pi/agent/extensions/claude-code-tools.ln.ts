/**
 * Compact, Claude-Code-style rendering for pi's built-in tools.
 *
 * Overrides read/bash/edit/write/grep/find/ls to render as tight rows instead
 * of pi's default padded boxes. Execution is delegated to the original built-in
 * tools untouched — only the TUI rendering changes.
 *
 *   ⏺ read frontend/apps/builder/package.json
 *     ⎿ 42 lines
 *
 * A run of consecutive `read` calls folds into one expandable header. The fold
 * is derived from pi's canonical message branch (not render order), so it stays
 * correct across scroll/resize re-renders:
 *
 *   ⏺ read 9 files
 *     ⎿ 9 files · 465 lines (ctrl+e to expand)
 */

import type { ExtensionAPI, Theme, ThemeColor } from "@earendil-works/pi-coding-agent";
import {
	createBashTool,
	createEditTool,
	createFindTool,
	createGrepTool,
	createLsTool,
	createReadTool,
	createWriteTool,
	keyHint,
} from "@earendil-works/pi-coding-agent";
import { Spacer, Text } from "@earendil-works/pi-tui";

const CALL_GLYPH = "⏺";
const RESULT_GLYPH = "⎿";
const PREVIEW_LINES = 12;
const COMMAND_WIDTH = 72;
const RENDER_SHELL = "self" as const;

type ToolText = { content: Array<{ type: string; text?: string }>; details?: unknown };
type RenderOptions = { expanded?: boolean; isPartial?: boolean };
type Summary = [ThemeColor, string];

const outputText = (result: ToolText) => {
	const first = result.content[0];
	return first?.type === "text" ? first.text ?? "" : "";
};

const firstLine = (text: string) => text.split("\n")[0];
const nonEmptyLineCount = (text: string) => text.split("\n").filter((line) => line.trim()).length;
const isErrorResult = (result: ToolText) => outputText(result).startsWith("Error");
const clip = (text: string, width: number) => (text.length > width ? `${text.slice(0, width - 1)}…` : text);
const locationSuffix = (location?: string) => (location ? ` in ${location}` : "");
const baseName = (path: string) => path.split("/").pop() || path;

const callLine = (theme: Theme, name: string, target: string) =>
	new Text(
		`${theme.fg("toolTitle", theme.bold(CALL_GLYPH))} ${theme.fg("muted", name)} ${theme.fg("accent", target)}`,
		0,
		0,
	);

const previewFromOutput = (result: ToolText) => outputText(result).split("\n").slice(0, PREVIEW_LINES);

type FinishResult = {
	theme: Theme;
	options: RenderOptions;
	result: ToolText;
	verb: string;
	summary: () => Summary;
	preview?: (result: ToolText) => string[];
};

const finishResult = ({ theme, options, result, verb, summary, preview = previewFromOutput }: FinishResult) => {
	if (options.isPartial) return new Text(theme.fg("warning", `${verb}…`), 0, 0);
	if (isErrorResult(result)) return new Text(theme.fg("error", firstLine(outputText(result))), 0, 0);

	const [color, body] = summary();
	let text = `  ${theme.fg("muted", RESULT_GLYPH)} ${theme.fg(color, body)}`;
	if (options.expanded) {
		for (const line of preview(result)) text += `\n     ${theme.fg("dim", line)}`;
	}
	return new Text(text, 0, 0);
};

const readRange = (args: { offset?: number; limit?: number }) => {
	const parts: string[] = [];
	if (args.offset) parts.push(`offset ${args.offset}`);
	if (args.limit) parts.push(`limit ${args.limit}`);
	return parts.length ? ` (${parts.join(", ")})` : "";
};

const bashSummary = (result: ToolText): Summary => {
	const text = outputText(result);
	const exit = text.match(/exit code: (\d+)/);
	const code = exit ? Number(exit[1]) : 0;
	const lines = nonEmptyLineCount(text);
	if (code !== 0) return ["error", `exit ${code}`];
	return ["success", lines ? `ok · ${lines} lines` : "ok"];
};

const editDiff = (result: ToolText) => (result.details as { diff?: string } | undefined)?.diff ?? "";
const diffCount = (diff: string, marker: string) =>
	diff.split("\n").filter((line) => line.startsWith(marker) && !line.startsWith(marker.repeat(3))).length;
const editSummary = (result: ToolText): Summary => {
	const diff = editDiff(result);
	return ["success", `+${diffCount(diff, "+")} -${diffCount(diff, "-")}`];
};
const editPreview = (result: ToolText) => editDiff(result).split("\n").slice(0, PREVIEW_LINES);

type ReadMember = { toolCallId: string; path: string };
type ReadRun = { members: ReadMember[]; index: number };
type ReadAnalysis = { runs: Map<string, ReadRun>; lineCounts: Map<string, number> };

type ToolCallBlock = { type: "toolCall"; id: string; name: string; arguments?: { path?: string } };
type AssistantBlock = ToolCallBlock | { type: "text"; text: string } | { type: "thinking" | "image" };
type BranchMessage =
	| { role: "assistant"; content: AssistantBlock[] }
	| { role: "toolResult"; toolName: string; toolCallId: string; content: Array<{ type: string; text?: string }> }
	| { role: "user" };
type BranchEntry = { type: string; message?: BranchMessage };
type SessionLike = { getBranch: () => BranchEntry[] };

const analyzeReads = (branch: BranchEntry[]): ReadAnalysis => {
	const runs = new Map<string, ReadRun>();
	const lineCounts = new Map<string, number>();
	let run: ReadMember[] = [];

	const flush = () => {
		run.forEach((member, index) => runs.set(member.toolCallId, { members: run, index }));
		run = [];
	};

	for (const { message } of branch) {
		if (!message) continue;
		if (message.role === "assistant") {
			for (const block of message.content) {
				if (block.type === "text" && block.text.trim()) flush();
				else if (block.type === "toolCall" && block.name === "read")
					run.push({ toolCallId: block.id, path: block.arguments?.path ?? "" });
				else if (block.type === "toolCall") flush();
			}
		} else if (message.role === "toolResult" && message.toolName === "read") {
			const first = message.content[0];
			if (first?.type === "text") lineCounts.set(message.toolCallId, (first.text ?? "").split("\n").length);
		} else if (message.role === "user") {
			flush();
		}
	}
	flush();
	return { runs, lineCounts };
};

export default function (pi: ExtensionAPI) {
	const cwd = process.cwd();

	let session: SessionLike | undefined;
	const headInvalidate = new Map<string, () => void>();
	const headRenderedSize = new Map<string, number>();

	pi.on("session_start", async (_event, ctx) => {
		session = ctx.sessionManager as unknown as SessionLike;
		headInvalidate.clear();
		headRenderedSize.clear();
	});

	const currentAnalysis = () => (session ? analyzeReads(session.getBranch()) : undefined);
	const refreshHeadIfStale = (run: ReadRun) => {
		const headId = run.members[0].toolCallId;
		if (headRenderedSize.get(headId) !== run.members.length) headInvalidate.get(headId)?.();
	};

	const read = createReadTool(cwd);
	pi.registerTool({
		name: "read",
		label: "read",
		description: read.description,
		parameters: read.parameters,
		renderShell: RENDER_SHELL,
		execute: (id, params, signal, onUpdate) => read.execute(id, params, signal, onUpdate),
		renderCall: (args, theme, context) => {
			const run = currentAnalysis()?.runs.get(context.toolCallId);
			if (run && run.index > 0) {
				refreshHeadIfStale(run);
				return new Spacer(0);
			}
			headInvalidate.set(context.toolCallId, context.invalidate);
			const size = run?.members.length ?? 1;
			headRenderedSize.set(context.toolCallId, size);
			return callLine(theme, "read", size <= 1 ? args.path + readRange(args) : `${size} files`);
		},
		renderResult: (result, options, theme, context) => {
			const analysis = currentAnalysis();
			const run = analysis?.runs.get(context.toolCallId);
			if (run && run.index > 0) {
				refreshHeadIfStale(run);
				return new Spacer(0);
			}
			const size = run?.members.length ?? 1;
			if (size <= 1) {
				return finishResult({
					theme,
					options,
					result,
					verb: "reading",
					summary: (): Summary => ["success", `${nonEmptyLineCount(outputText(result))} lines`],
				});
			}

			const counts = analysis!.lineCounts;
			const total = run!.members.reduce((sum, member) => sum + (counts.get(member.toolCallId) ?? 0), 0);
			const head = `${theme.fg("muted", RESULT_GLYPH)} ${theme.fg("success", `${size} files · ${total} lines`)}`;
			if (!options.expanded) {
				return new Text(`  ${head} ${theme.fg("dim", `(${keyHint("app.tools.expand", "expand")})`)}`, 0, 0);
			}
			let text = `  ${head}`;
			for (const member of run!.members) {
				const lines = counts.get(member.toolCallId);
				text += `\n     ${theme.fg("accent", baseName(member.path))}${theme.fg("dim", lines ? ` · ${lines} lines` : "")}`;
			}
			return new Text(text, 0, 0);
		},
	});

	const bash = createBashTool(cwd);
	pi.registerTool({
		name: "bash",
		label: "bash",
		description: bash.description,
		parameters: bash.parameters,
		renderShell: RENDER_SHELL,
		execute: (id, params, signal, onUpdate) => bash.execute(id, params, signal, onUpdate),
		renderCall: (args, theme) => callLine(theme, "$", clip(args.command, COMMAND_WIDTH)),
		renderResult: (result, options, theme) =>
			finishResult({ theme, options, result, verb: "running", summary: () => bashSummary(result) }),
	});

	const edit = createEditTool(cwd);
	pi.registerTool({
		name: "edit",
		label: "edit",
		description: edit.description,
		parameters: edit.parameters,
		renderShell: RENDER_SHELL,
		execute: (id, params, signal, onUpdate) => edit.execute(id, params, signal, onUpdate),
		renderCall: (args, theme) => callLine(theme, "edit", args.path),
		renderResult: (result, options, theme) =>
			finishResult({ theme, options, result, verb: "editing", summary: () => editSummary(result), preview: editPreview }),
	});

	const write = createWriteTool(cwd);
	pi.registerTool({
		name: "write",
		label: "write",
		description: write.description,
		parameters: write.parameters,
		renderShell: RENDER_SHELL,
		execute: (id, params, signal, onUpdate) => write.execute(id, params, signal, onUpdate),
		renderCall: (args, theme) => callLine(theme, "write", `${args.path} (${args.content.split("\n").length} lines)`),
		renderResult: (result, options, theme) =>
			finishResult({ theme, options, result, verb: "writing", summary: (): Summary => ["success", "written"] }),
	});

	const grep = createGrepTool(cwd);
	pi.registerTool({
		name: "grep",
		label: "grep",
		description: grep.description,
		parameters: grep.parameters,
		renderShell: RENDER_SHELL,
		execute: (id, params, signal, onUpdate) => grep.execute(id, params, signal, onUpdate),
		renderCall: (args, theme) => callLine(theme, "grep", args.pattern + locationSuffix(args.path ?? args.glob)),
		renderResult: (result, options, theme) =>
			finishResult({
				theme,
				options,
				result,
				verb: "searching",
				summary: (): Summary => ["success", `${nonEmptyLineCount(outputText(result))} matches`],
			}),
	});

	const find = createFindTool(cwd);
	pi.registerTool({
		name: "find",
		label: "find",
		description: find.description,
		parameters: find.parameters,
		renderShell: RENDER_SHELL,
		execute: (id, params, signal, onUpdate) => find.execute(id, params, signal, onUpdate),
		renderCall: (args, theme) => callLine(theme, "find", args.pattern + locationSuffix(args.path)),
		renderResult: (result, options, theme) =>
			finishResult({
				theme,
				options,
				result,
				verb: "finding",
				summary: (): Summary => ["success", `${nonEmptyLineCount(outputText(result))} files`],
			}),
	});

	const ls = createLsTool(cwd);
	pi.registerTool({
		name: "ls",
		label: "ls",
		description: ls.description,
		parameters: ls.parameters,
		renderShell: RENDER_SHELL,
		execute: (id, params, signal, onUpdate) => ls.execute(id, params, signal, onUpdate),
		renderCall: (args, theme) => callLine(theme, "ls", args.path ?? "."),
		renderResult: (result, options, theme) =>
			finishResult({
				theme,
				options,
				result,
				verb: "listing",
				summary: (): Summary => ["success", `${nonEmptyLineCount(outputText(result))} entries`],
			}),
	});
}
