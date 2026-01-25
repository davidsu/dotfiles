const KEYS = [
  "ctrl-b", "ctrl-f", "ctrl-g", "ctrl-h", "ctrl-j", "ctrl-q", "ctrl-v", "ctrl-x",
  "ctrl-r", "ctrl-t", "ctrl-y", "ctrl-l", "ctrl-d",
  "alt-a", "alt-b", "alt-c", "alt-d", "alt-e", "alt-f", "alt-g", "alt-h",
  "alt-i", "alt-j", "alt-k", "alt-l", "alt-m", "alt-n", "alt-o", "alt-p",
  "alt-q", "alt-r", "alt-s", "alt-t", "alt-u", "alt-v", "alt-w", "alt-x",
  "alt-y", "alt-z"
];

export const humanizeKey = (key) =>
  key
    .split("_")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ") + ":";

export const shouldMask = (key) => {
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

export const getMaskForKey = (key) => {
  if (key === "number") return "•••• •••• •••• ••••";
  if (key === "code" || key === "cvv") return "•••";
  return "••••••••";
};

export const createKeybindGenerator = () => {
  const keys = [...KEYS].reverse();

  return () => {
    const rawKey = keys.pop();
    if (!rawKey) return { rawKey: "", displayKey: "" };

    const displayKey = rawKey.replace("ctrl-", "Ctrl+").replace("alt-", "Alt+");
    return { rawKey, displayKey };
  };
};

const extractData = (json, nextKeybind) =>
  Object.entries(json.data || {})
    .filter(([key, value]) => value && typeof value === "string")
    .map(([key, value]) => {
      const { rawKey, displayKey } = nextKeybind();
      return {
        label: humanizeKey(key),
        displayValue: shouldMask(key) ? getMaskForKey(key) : value,
        rawValue: value,
        rawKey,
        displayKey,
      };
    });

const extractUris = (json, nextKeybind) => {
  const firstUri = json.data?.uris?.[0]?.uri;
  if (!firstUri) return [];

  const { rawKey, displayKey } = nextKeybind();
  return [{
    label: "Website:",
    displayValue: firstUri,
    rawValue: firstUri,
    rawKey,
    displayKey,
  }];
};

const extractFields = (json, nextKeybind) =>
  (json.fields || []).map((field) => {
    const { rawKey, displayKey } = nextKeybind();
    return {
      label: field.name + ":",
      displayValue: field.type === "hidden" ? "•••••••" : field.value,
      rawValue: field.value,
      rawKey,
      displayKey,
    };
  });

const extractNotes = (json) =>
  json.notes
    ? [{
        label: "Notes:",
        displayValue: json.notes,
        rawValue: json.notes,
        rawKey: "",
        displayKey: "",
      }]
    : [];

const DUMMY = { label: " ", displayValue: " ", rawValue: null, rawKey: "", displayKey: "" };

export const extractEntries = (json, nextKeybind) => [
  ...extractData(json, nextKeybind),
  ...extractUris(json, nextKeybind),
  DUMMY,
  ...extractFields(json, nextKeybind),
  DUMMY,
  ...extractNotes(json),
];
