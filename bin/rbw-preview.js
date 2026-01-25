#!/usr/bin/env bun

const COLUMN_WIDTH = 60;
const KEYS = [
  "ctrl-b", "ctrl-f", "ctrl-g", "ctrl-h", "ctrl-j", "ctrl-q", "ctrl-v", "ctrl-x",
  "ctrl-r", "ctrl-t", "ctrl-y", "ctrl-l", "ctrl-d",
  "alt-a", "alt-b", "alt-c", "alt-d", "alt-e", "alt-f", "alt-g", "alt-h",
  "alt-i", "alt-j", "alt-k", "alt-l", "alt-m", "alt-n", "alt-o", "alt-p",
  "alt-q", "alt-r", "alt-s", "alt-t", "alt-u", "alt-v", "alt-w", "alt-x",
  "alt-y", "alt-z"
];

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

const keys = [...KEYS].reverse();
const content = [];

const calculatePadding = (text) =>
  " ".repeat(Math.max(0, COLUMN_WIDTH - text.length));

const humanizeKey = (key) =>
  key
    .split("_")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ") + ":";

const shouldMask = (key) => {
  const sensitive = [
    "password",
    "number",
    "code",
    "totp",
    "cvv",
    "ssn",
    "passport_number",
  ];
  return sensitive.includes(key.toLowerCase());
};

const getMaskForKey = (key) => {
  if (key === "number") return "•••• •••• •••• ••••";
  if (key === "code" || key === "cvv") return "•••";
  return "••••••••";
};

const addLine = (line) => content.push(line);
const addBlankLine = () => addLine("");

const nextKeybind = () => {
  const key = keys.pop();
  if (!key) return "";

  const display = key.replace("ctrl-", "Ctrl+").replace("alt-", "Alt+");
  return colors.green(`[${display}]`);
};

const printField = (color, { displayValue, label, keybind }) => {
  if (!displayValue) return;

  const coloredLabel = color(label);
  const text = `${label} ${displayValue}`;
  const padding = calculatePadding(text);

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

const extractData = (json) =>
  Object.entries(json.data || {})
    .filter(([key, value]) => value && typeof value === "string")
    .map(([key, value]) => ({
      label: humanizeKey(key),
      displayValue: shouldMask(key) ? getMaskForKey(key) : value,
      keybind: nextKeybind(),
    }));

const extractUris = (json) => {
  const firstUri = json.data?.uris?.[0]?.uri;
  return firstUri
    ? [{ label: "Website:", displayValue: firstUri, keybind: nextKeybind() }]
    : [];
};

const extractFields = (json) =>
  (json.fields || []).map((field) => ({
    label: field.name + ":",
    displayValue: field.type === "hidden" ? "•••••••" : field.value,
    keybind: nextKeybind(),
  }));

const extractNotes = (json) =>
  json.notes
    ? [{ label: "Notes:", displayValue: json.notes, keybind: "" }]
    : [];

const DUMMY = { label: " ", displayValue: " ", keybind: "" };

const extractEntries = (json) => [
  ...extractData(json),
  ...extractUris(json),
  DUMMY,
  ...extractFields(json),
  DUMMY,
  ...extractNotes(json),
];

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
