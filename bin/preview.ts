#!/usr/bin/env bun

import { spawnSync } from 'child_process'
import { accessSync, constants } from 'fs'
import { homedir } from 'os'

// Parse file[:line][:col] format, returns { file, line }
function parseFileLineArg(arg: string) {
  const parts = arg.split(':')
  let file = parts[0]
  let lineStr = parts[1]

  // Handle Windows paths like C:\path (just in case)
  if (/^[A-Z]:\\/.test(arg)) {
    file = `${parts[0]}:${parts[1]}`
    lineStr = parts[2]
  }

  // Validate line number starts with digit
  if (lineStr && !/^[0-9]/.test(lineStr)) {
    return { file, line: 0, valid: false }
  }

  // Strip non-numeric characters from line number
  const line = lineStr ? parseInt(lineStr.replace(/[^0-9].*/g, ''), 10) || 0 : 0

  return { file, line, valid: true }
}

// Expand ~ to home directory
function expandTilde(filePath: string) {
  if (filePath.startsWith('~/')) {
    return filePath.replace(/^~\//, `${homedir()}/`)
  }
  return filePath
}

// Check if file is readable
function isReadable(filePath: string) {
  try {
    accessSync(filePath, constants.R_OK)
    return true
  } catch {
    return false
  }
}

// Check if file is binary using `file --mime`
function isBinaryFile(filePath: string) {
  const result = spawnSync('file', ['--dereference', '--mime', filePath], {
    encoding: 'utf-8',
  })

  const mime = result.stdout || ''
  // Check the part after the filename for "binary"
  const mimeTypeSection = mime.substring(filePath.length)
  return { isBinary: mimeTypeSection.includes('binary'), mime }
}

// Check if bat is available
function hasBat() {
  const result = spawnSync('command', ['-v', 'bat'], { shell: true })
  return result.status === 0
}

// Preview file with bat (syntax highlighting) or cat (fallback)
function previewFile(filePath: string, highlightLine: number) {
  if (hasBat()) {
    const batStyle = process.env.BAT_STYLE || 'numbers'
    const result = spawnSync(
      'bat',
      [
        `--style=${batStyle}`,
        '--color=always',
        '--pager=never',
        `--highlight-line=${highlightLine}`,
        filePath,
      ],
      { stdio: 'inherit' }
    )
    process.exit(result.status ?? 0)
  }

  // Fallback to cat
  spawnSync('cat', [filePath], { stdio: 'inherit' })
}

function main() {
  const arg = process.argv[2]

  if (!arg) {
    console.log(`usage: ${process.argv[1]} FILENAME[:LINENO][:IGNORED]`)
    process.exit(1)
  }

  const { file: rawFile, line, valid } = parseFileLineArg(arg)

  if (!valid) {
    process.exit(1)
  }

  const file = expandTilde(rawFile)

  if (!isReadable(file)) {
    console.log(`File not found: ${file}`)
    process.exit(1)
  }

  const { isBinary, mime } = isBinaryFile(file)
  if (isBinary) {
    console.log(mime)
    process.exit(0)
  }

  previewFile(file, line)
}

main()
