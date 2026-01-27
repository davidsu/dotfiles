#!/usr/bin/env bun

import { $ } from 'bun'
import { extractEntries } from './rbw-fields'

const copyToClipboard = (value: string, label: string) => {
  Bun.spawnSync(['pbcopy'], { stdin: new TextEncoder().encode(value) })
  console.log(`\u2713 ${label} copied to clipboard`)
  process.exit(0)
}

const main = async () => {
  const [entry, targetKeybind] = process.argv.slice(2)

  if (!entry || !targetKeybind) {
    process.exit(1)
  }

  const jsonResult = await $`rbw get ${entry} --raw`.text().catch(() => null)
  if (!jsonResult) {
    process.exit(1)
  }

  const json = JSON.parse(jsonResult)
  const entries = extractEntries(json)

  for (const field of entries) {
    if (field.rawKey === targetKeybind && field.rawValue) {
      copyToClipboard(field.rawValue, field.label)
    }
  }

  process.exit(0)
}

main()
