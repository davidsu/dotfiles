#!/usr/bin/env bun

import { $ } from "bun";
import { extractEntries, createKeybindGenerator } from "./rbw-fields.js";

const copyToClipboard = (value, label) => {
  Bun.spawnSync(["pbcopy"], { stdin: new TextEncoder().encode(value) });
  console.log(`✓ ${label} copied to clipboard`);
  process.exit(0);
};

const main = async () => {
  const [entry, targetKeybind] = process.argv.slice(2);

  if (!entry || !targetKeybind) {
    process.exit(1);
  }

  const jsonResult = await $`rbw get ${entry} --raw`.text().catch(() => null);
  if (!jsonResult) {
    process.exit(1);
  }

  const json = JSON.parse(jsonResult);
  const nextKeybind = createKeybindGenerator();
  const entries = extractEntries(json, nextKeybind);

  for (const entry of entries) {
    if (entry.rawKey === targetKeybind && entry.rawValue) {
      copyToClipboard(entry.rawValue, entry.label);
    }
  }

  process.exit(1);
};

main();
