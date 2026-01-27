#!/usr/bin/env bun

import { extractEntries, type FieldEntry } from './rbw-fields'

const COLUMN_WIDTH = 60

// ANSI color helpers
const colors = {
  cyan: (s: string) => `\x1b[1;36m${s}\x1b[0m`,
  yellow: (s: string) => `\x1b[33m${s}\x1b[0m`,
  green: (s: string) => `\x1b[32m${s}\x1b[0m`,
  blue: (s: string) => `\x1b[36m${s}\x1b[0m`,
  magenta: (s: string) => `\x1b[35m${s}\x1b[0m`,
  gray: (s: string) => `\x1b[90m${s}\x1b[0m`,
}

type ColorFn = (s: string) => string

const fieldColors: ColorFn[] = [
  colors.blue,
  colors.green,
  colors.cyan,
  colors.magenta,
  colors.yellow,
]

// Deterministic color based on label hash
const hashLabel = (label: string) => {
  let hash = 0
  for (let i = 0; i < label.length; i++) {
    hash += label.charCodeAt(i) * (i + 1)
  }
  return hash % fieldColors.length
}

// Build output content
const content: string[] = []

const calculatePadding = (text: string) =>
  ' '.repeat(Math.max(0, COLUMN_WIDTH - text.length))

const addLine = (line: string) => content.push(line)
const addBlankLine = () => addLine('')

const printField = (color: ColorFn, entry: FieldEntry) => {
  if (!entry.displayValue) return

  const coloredLabel = color(entry.label)
  const text = `${entry.label} ${entry.displayValue}`
  const padding = calculatePadding(text)
  const keybind = entry.displayKey ? colors.green(`[${entry.displayKey}]`) : ''

  addLine(`${coloredLabel} ${entry.displayValue}${padding}${keybind}`)
}

const renderFooter = () => {
  const terminalLines = process.stdout.rows || 40
  const previewHeight = Math.floor(terminalLines / 2) - 3
  const paddingLines = Math.max(0, previewHeight - content.length - 2)

  console.log(content.join('\n'))
  console.log('\n'.repeat(paddingLines))
  console.log(colors.gray('\u2501'.repeat(40)))
  console.log(
    colors.gray('Navigation: ') +
      colors.green('Ctrl+P/N') +
      ' up/down  ' +
      colors.green('Ctrl+/') +
      ' toggle  ' +
      colors.green('Ctrl+O') +
      ' open URL  ' +
      colors.green('Ctrl+S') +
      ' sort'
  )
}

const fetchEntry = async (entryName: string) => {
  const proc = Bun.spawn(['rbw', 'get', entryName, '--raw'], {
    stdout: 'pipe',
    stderr: 'pipe',
  })

  const output = await new Response(proc.stdout).text()
  const exitCode = await proc.exited

  if (exitCode !== 0) return null

  try {
    return JSON.parse(output)
  } catch {
    return null
  }
}

const main = async () => {
  const entryName = process.argv[2]

  if (!entryName) {
    console.log('No entry selected')
    process.exit(0)
  }

  const json = await fetchEntry(entryName)

  if (!json) {
    console.log('Failed to fetch entry')
    process.exit(0)
  }

  const entries = extractEntries(json)

  addLine(colors.cyan(`\u2501\u2501\u2501 ${entryName} \u2501\u2501\u2501`))
  addBlankLine()

  for (const entry of entries) {
    const color =
      entry.label === 'Website:'
        ? colors.green
        : fieldColors[hashLabel(entry.label)]
    printField(color, entry)
  }

  renderFooter()
}

main()
