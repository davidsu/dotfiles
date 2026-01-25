#!/usr/bin/env bun

import { extractEntries } from "./rbw-fields.js";

const COLUMN_WIDTH = 60;

const colors = {
  cyan: (s) => `\x1b[1;36m${s}\x1b[0m`,
  yellow: (s) => `\x1b[33m${s}\x1b[0m`,
  green: (s) => `\x1b[32m${s}\x1b[0m`,
  blue: (s) => `\x1b[36m${s}\x1b[0m`,
  magenta: (s) => `\x1b[35m${s}\x1b[0m`,
  gray: (s) => `\x1b[90m${s}\x1b[0m`,
};

const fieldColors = [
  colors.blue,
  colors.green,
  colors.cyan,
  colors.magenta,
  colors.yellow,
];

const hashLabel = (label) => {
  let hash = 0;
  for (let i = 0; i < label.length; i++) {
    hash += label.charCodeAt(i) * (i + 1);
  }
  return hash % fieldColors.length;
};

const content = [];

const calculatePadding = (text) =>
  " ".repeat(Math.max(0, COLUMN_WIDTH - text.length));

const addLine = (line) => content.push(line);
const addBlankLine = () => addLine("");

const printField = (color, { displayValue, label, displayKey }) => {
  if (!displayValue) return;

  const coloredLabel = color(label);
  const text = `${label} ${displayValue}`;
  const padding = calculatePadding(text);
  const keybind = displayKey ? colors.green(`[${displayKey}]`) : "";

  addLine(`${coloredLabel} ${displayValue}${padding}${keybind}`);
};

const renderFooter = () => {
  const terminalLines = process.stdout.rows || 40;
  const previewHeight = Math.floor(terminalLines / 2) - 3;
  const paddingLines = Math.max(0, previewHeight - content.length - 2);

  console.log(content.join("\n"));
  console.log("\n".repeat(paddingLines));
  console.log(colors.gray("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"));
  console.log(
    colors.gray("Navigation: ") +
      colors.green("Ctrl+P/N") +
      " up/down  " +
      colors.green("Ctrl+/") +
      " toggle  " +
      colors.green("Ctrl+O") +
      " open URL  " +
      colors.green("Ctrl+S") +
      " sort",
  );
};

const fetchEntry = async (entryName) => {
  const proc = Bun.spawn(["rbw", "get", entryName, "--raw"], {
    stdout: "pipe",
    stderr: "pipe",
  });

  const output = await new Response(proc.stdout).text();
  const exitCode = await proc.exited;

  if (exitCode !== 0) return null;

  try {
    return JSON.parse(output);
  } catch {
    return null;
  }
};


const main = async () => {
  const entryName = process.argv[2];

  if (!entryName) {
    console.log("No entry selected");
    process.exit(0);
  }

  const json = await fetchEntry(entryName);

  if (!json) {
    console.log("Failed to fetch entry");
    process.exit(0);
  }

  const entries = extractEntries(json);

  addLine(colors.cyan(`━━━ ${entryName} ━━━`));
  addBlankLine();

  for (const entry of entries) {
    const color =
      entry.label === "Website:"
        ? colors.green
        : fieldColors[hashLabel(entry.label)];
    printField(color, entry);
  }

  renderFooter();
};

main();
