/**
 * Compact, Claude-Code-style rendering for pi's built-in tools.
 *
 * Overrides read/bash/edit/write/grep/find/ls to render as a single tight line
 * each, instead of pi's default padded boxes. Execution is delegated to the
 * original built-in tools untouched — only the TUI rendering changes.
 *
 *   ⏺ read frontend/apps/builder/package.json · 42 lines
 *
 * The whole row is rendered from the `renderCall` slot (the only slot pi paints
 * before a result exists, so the row is never blank while a slow tool runs);
 * the result is read back from the canonical session branch. `renderResult` is
 * always empty.
 *
 * A run of consecutive same-tool calls (read, grep) folds into one expandable
 * header, derived from the branch so it survives scroll/resize re-renders:
 *
 *   ⏺ read 9 files · 465 lines (ctrl+e to expand)
 */

import type { AgentTool } from "@earendil-works/pi-agent-core";
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
const PREVIEW_LINES = 12;
const COMMAND_WIDTH = 72;
const LABEL_WIDTH = 50;
const RENDER_SHELL = "self" as const;

type ToolText = { content: Array<{ type: string; text?: string }>; details?: unknown };
type Summary = [ThemeColor, string];
type ToolArgs = {
	path?: string;
	pattern?: string;
	glob?: string;
	offset?: number;
	limit?: number;
	command?: string;
	content?: string;
};

const outputText = (result: ToolText) => {
	const first = result.content[0];
	return first?.type === "text" ? first.text ?? "" : "";
};

const firstLine = (text: string) => text.split("\n")[0];
const totalLineCount = (text: string) => text.split("\n").length;
const nonEmptyLineCount = (text: string) => text.split("\n").filter((line) => line.trim()).length;
const isErrorResult = (result: ToolText) => outputText(result).startsWith("Error");
const clip = (text: string, width: number) => (text.length > width ? `${text.slice(0, width - 1)}…` : text);
const locationSuffix = (location?: string) => (location ? ` in ${location}` : "");
const baseName = (path: string) => path.split("/").pop() || path;
const previewFromOutput = (result: ToolText) => outputText(result).split("\n").slice(0, PREVIEW_LINES);

const oneLine = (theme: Theme, name: string, target: string, summary: Summary | undefined, verb: string) => {
	const head = `${theme.fg("toolTitle", theme.bold(CALL_GLYPH))} ${theme.fg("muted", name)} ${theme.fg("accent", target)}`;
	if (!summary) return `${head} ${theme.fg("dim", `· ${verb}…`)}`;
	const [color, body] = summary;
	return `${head} ${theme.fg("dim", "·")} ${theme.fg(color, body)}`;
};

const indented = (theme: Theme, label: string, detail: string) =>
	`\n     ${theme.fg("accent", label)}${detail ? theme.fg("dim", ` · ${detail}`) : ""}`;

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
const editSummary = (result: ToolText): Summary => ["success", `+${diffCount(editDiff(result), "+")} -${diffCount(editDiff(result), "-")}`];
const editPreview = (result: ToolText) => editDiff(result).split("\n").slice(0, PREVIEW_LINES);

type SingleSpec = {
	name: string;
	display: string;
	verb: string;
	target: (args: ToolArgs) => string;
	summary: (result: ToolText) => Summary;
	preview?: (result: ToolText) => string[];
};

const SINGLES: SingleSpec[] = [
	{ name: "bash", display: "$", verb: "running", target: (args) => clip(args.command ?? "", COMMAND_WIDTH), summary: bashSummary },
	{ name: "edit", display: "edit", verb: "editing", target: (args) => args.path ?? "", summary: editSummary, preview: editPreview },
	{
		name: "write",
		display: "write",
		verb: "writing",
		target: (args) => `${args.path ?? ""} (${(args.content ?? "").split("\n").length} lines)`,
		summary: (): Summary => ["success", "written"],
	},
	{
		name: "find",
		display: "find",
		verb: "finding",
		target: (args) => (args.pattern ?? "") + locationSuffix(args.path),
		summary: (result): Summary => ["success", `${nonEmptyLineCount(outputText(result))} files`],
	},
	{
		name: "ls",
		display: "ls",
		verb: "listing",
		target: (args) => args.path ?? ".",
		summary: (result): Summary => ["success", `${nonEmptyLineCount(outputText(result))} entries`],
	},
];

type GroupSpec = {
	name: string;
	noun: string;
	unit: string;
	verb: string;
	label: (args: ToolArgs) => string;
	target: (args: ToolArgs) => string;
	metric: (text: string) => number;
};

const GROUPS: GroupSpec[] = [
	{
		name: "read",
		noun: "files",
		unit: "lines",
		verb: "reading",
		label: (args) => baseName(args.path ?? ""),
		target: (args) => args.path ?? "",
		metric: totalLineCount,
	},
	{
		name: "grep",
		noun: "searches",
		unit: "matches",
		verb: "searching",
		label: (args) => clip(args.pattern ?? "", LABEL_WIDTH),
		target: (args) => (args.pattern ?? "") + locationSuffix(args.path ?? args.glob),
		metric: nonEmptyLineCount,
	},
];
const groupSpecByName = new Map(GROUPS.map((spec) => [spec.name, spec]));

type GroupMember = { toolCallId: string; label: string };
type GroupRun = { spec: GroupSpec; members: GroupMember[]; index: number };
type RunAnalysis = { runs: Map<string, GroupRun>; results: Map<string, ToolText> };

type ToolCallBlock = { type: "toolCall"; id: string; name: string; arguments?: ToolArgs };
type AssistantBlock = ToolCallBlock | { type: "text"; text: string } | { type: "thinking" | "image" };
type BranchMessage =
	| { role: "assistant"; content: AssistantBlock[] }
	| { role: "toolResult"; toolName: string; toolCallId: string; content: ToolText["content"]; details?: unknown }
	| { role: "user" };
type BranchEntry = { type: string; message?: BranchMessage };
type SessionLike = { getBranch: () => BranchEntry[] };

const analyzeRuns = (branch: BranchEntry[]): RunAnalysis => {
	const runs = new Map<string, GroupRun>();
	const results = new Map<string, ToolText>();
	let members: GroupMember[] = [];
	let spec: GroupSpec | undefined;

	const flush = () => {
		if (spec) {
			const run = { spec, members };
			members.forEach((member, index) => runs.set(member.toolCallId, { ...run, index }));
		}
		members = [];
		spec = undefined;
	};

	for (const { message } of branch) {
		if (!message) continue;
		if (message.role === "assistant") {
			for (const block of message.content) {
				if (block.type === "text" && block.text.trim()) flush();
				else if (block.type === "toolCall") {
					const blockSpec = groupSpecByName.get(block.name);
					if (!blockSpec) flush();
					else {
						if (spec && spec.name !== blockSpec.name) flush();
						spec = blockSpec;
						members.push({ toolCallId: block.id, label: blockSpec.label(block.arguments ?? {}) });
					}
				}
			}
		} else if (message.role === "toolResult") {
			results.set(message.toolCallId, { content: message.content, details: message.details });
		} else if (message.role === "user") {
			flush();
		}
	}
	flush();
	return { runs, results };
};

let session: SessionLike | undefined;
const headInvalidate = new Map<string, () => void>();
const headSignature = new Map<string, string>();
const emptyResults = new Map<string, ToolText>();

const currentAnalysis = () => (session ? analyzeRuns(session.getBranch()) : undefined);
const memberMetric = (spec: GroupSpec, results: Map<string, ToolText>, toolCallId: string) => {
	const result = results.get(toolCallId);
	return result ? spec.metric(outputText(result)) : undefined;
};
const runSignature = (run: GroupRun, results: Map<string, ToolText>) =>
	`${run.members.length}:${run.members.reduce((sum, member) => sum + (memberMetric(run.spec, results, member.toolCallId) ?? 0), 0)}`;
const refreshHeadIfStale = (run: GroupRun, results: Map<string, ToolText>) => {
	const headId = run.members[0].toolCallId;
	if (headSignature.get(headId) !== runSignature(run, results)) headInvalidate.get(headId)?.();
};

const groupedHead = (theme: Theme, run: GroupRun, results: Map<string, ToolText>, expanded: boolean) => {
	const spec = run.spec;
	const total = run.members.reduce((sum, member) => sum + (memberMetric(spec, results, member.toolCallId) ?? 0), 0);
	let text = oneLine(theme, spec.name, `${run.members.length} ${spec.noun}`, ["success", `${total} ${spec.unit}`], spec.verb);
	if (!expanded) return `${text} ${theme.fg("dim", `(${keyHint("app.tools.expand", "expand")})`)}`;
	for (const member of run.members) {
		const metric = memberMetric(spec, results, member.toolCallId);
		text += indented(theme, member.label, metric === undefined ? "" : `${metric} ${spec.unit}`);
	}
	return text;
};

const registerSingle = (pi: ExtensionAPI, spec: SingleSpec, tool: AgentTool<any>) =>
	pi.registerTool({
		name: spec.name,
		label: spec.name,
		description: tool.description,
		parameters: tool.parameters,
		renderShell: RENDER_SHELL,
		execute: (id, params, signal, onUpdate) => tool.execute(id, params, signal, onUpdate),
		renderCall: (args: ToolArgs, theme, context) => {
			const result = (currentAnalysis()?.results ?? emptyResults).get(context.toolCallId);
			const summary = result
				? isErrorResult(result)
					? (["error", firstLine(outputText(result))] as Summary)
					: spec.summary(result)
				: undefined;
			let text = oneLine(theme, spec.display, spec.target(args), summary, spec.verb);
			if (context.expanded && result) {
				for (const line of (spec.preview ?? previewFromOutput)(result)) text += `\n     ${theme.fg("dim", line)}`;
			}
			return new Text(text, 0, 0);
		},
		renderResult: () => new Spacer(0),
	});

const registerGrouped = (pi: ExtensionAPI, spec: GroupSpec, tool: AgentTool<any>) =>
	pi.registerTool({
		name: spec.name,
		label: spec.name,
		description: tool.description,
		parameters: tool.parameters,
		renderShell: RENDER_SHELL,
		execute: (id, params, signal, onUpdate) => tool.execute(id, params, signal, onUpdate),
		renderCall: (args: ToolArgs, theme, context) => {
			const analysis = currentAnalysis();
			const results = analysis?.results ?? emptyResults;
			const run = analysis?.runs.get(context.toolCallId);
			if (run && run.index > 0) {
				refreshHeadIfStale(run, results);
				return new Spacer(0);
			}
			headInvalidate.set(context.toolCallId, context.invalidate);
			if (run && run.members.length > 1) {
				headSignature.set(context.toolCallId, runSignature(run, results));
				return new Text(groupedHead(theme, run, results, context.expanded), 0, 0);
			}
			headSignature.set(context.toolCallId, `1:${memberMetric(spec, results, context.toolCallId) ?? 0}`);
			const result = results.get(context.toolCallId);
			const summary = result ? (["success", `${spec.metric(outputText(result))} ${spec.unit}`] as Summary) : undefined;
			return new Text(oneLine(theme, spec.name, spec.target(args), summary, spec.verb), 0, 0);
		},
		renderResult: () => new Spacer(0),
	});

export default function (pi: ExtensionAPI) {
	const cwd = process.cwd();
	const tools: Record<string, AgentTool<any>> = {
		read: createReadTool(cwd),
		bash: createBashTool(cwd),
		edit: createEditTool(cwd),
		write: createWriteTool(cwd),
		grep: createGrepTool(cwd),
		find: createFindTool(cwd),
		ls: createLsTool(cwd),
	};

	pi.on("session_start", async (_event, ctx) => {
		session = ctx.sessionManager as unknown as SessionLike;
		headInvalidate.clear();
		headSignature.clear();
	});

	for (const spec of GROUPS) registerGrouped(pi, spec, tools[spec.name]);
	for (const spec of SINGLES) registerSingle(pi, spec, tools[spec.name]);
}
