#!/usr/bin/env bun

import { $ } from "bun";
import { extractEntries } from "./rbw-fields.js";

const copyToClipboard = (value, label) => {
  Bun.spawnSync(["pbcopy"], { stdin: new TextEncoder().encode(value) });
  console.log(`✓ ${label} copied to clipboard`);
  process.exit(0);
};

const main = async () => {
  const [entry, indexStr] = process.argv.slice(2);
  const targetIndex = parseInt(indexStr, 10);

  if (!entry || isNaN(targetIndex)) {
    process.exit(1);
  }

  const jsonResult = await $`rbw get ${entry} --raw`.text().catch(() => null);
  if (!jsonResult) {
    process.exit(1);
  }

  const json = JSON.parse(jsonResult);
  const entries = extractEntries(json);

  let currentIndex = 1;
  for (const entry of entries) {
    if (!entry.rawValue) continue;

    if (currentIndex === targetIndex) {
      copyToClipboard(entry.rawValue, entry.label);
    }
    currentIndex++;
  }

  process.exit(1);
};

main();
