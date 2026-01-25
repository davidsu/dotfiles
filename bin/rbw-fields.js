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

export const extractData = (json) =>
  Object.entries(json.data || {})
    .filter(([key, value]) => value && typeof value === "string")
    .map(([key, value]) => ({
      label: humanizeKey(key),
      displayValue: shouldMask(key) ? getMaskForKey(key) : value,
      rawValue: value,
    }));

export const extractUris = (json) => {
  const firstUri = json.data?.uris?.[0]?.uri;
  return firstUri
    ? [{ label: "Website:", displayValue: firstUri, rawValue: firstUri }]
    : [];
};

export const extractFields = (json) =>
  (json.fields || []).map((field) => ({
    label: field.name + ":",
    displayValue: field.type === "hidden" ? "•••••••" : field.value,
    rawValue: field.value,
  }));

export const extractNotes = (json) =>
  json.notes
    ? [{ label: "Notes:", displayValue: json.notes, rawValue: json.notes }]
    : [];

export const DUMMY = { label: " ", displayValue: " ", rawValue: null };

export const extractEntries = (json) => [
  ...extractData(json),
  ...extractUris(json),
  DUMMY,
  ...extractFields(json),
  DUMMY,
  ...extractNotes(json),
];
