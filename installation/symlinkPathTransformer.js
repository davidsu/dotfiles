#!/usr/bin/env node

/**
 * Transforms symlink filenames to their destination paths
 *
 * Format: {name}.home[.{path}].symlink[.{extension}]
 * - DOT represents a literal dot (for hidden directories/files)
 * - Dots between path components become slashes
 *
 * Examples:
 *   CLAUDE.home.DOTclaude.symlink.md -> ~/.claude/CLAUDE.md
 *   DOTzshrc.home.symlink -> ~/.zshrc
 *   init.lua.home.DOTconfig.symlink -> ~/.config/init.lua
 */

const extractExtension = (filename) => filename.replace(/.*symlink/, '')
const removeSymlinkAndExtension = (filename) => filename.replace(/\.symlink.*$/, '')
const replaceDOTWithDot = (str) => str.replace(/DOT/g, '.')
const removeLeadingDot = (str) => (str ? str.substring(1) : '')

const transformPathToDirectory = (pathPart) => {
  if (!pathPart) return ''
  return '/' + pathPart.replace(/\./g, '/').replace(/DOT/g, '.')
}

const transformPath = (filename, homeDir) => {
  if (!/\.home/.test(filename)) return null

  const extension = extractExtension(filename)
  const base = removeSymlinkAndExtension(filename)
  const [namePart, ...rest] = base.split('.home')
  const name = replaceDOTWithDot(namePart)
  const pathPart = removeLeadingDot(rest.join('.home'))
  const directory = transformPathToDirectory(pathPart)

  return `${homeDir}${directory}/${name}${extension}`
}

const filename = process.argv[2]

const result = transformPath(filename, process.env.HOME)

if (result) {
  console.log(result)
} else {
  const errorMsg = filename
    ? `Could not parse filename: ${filename}`
    : 'Usage: symlinkPathTransformer.js <filename>'
  console.error(errorMsg)
  process.exit(1)
}
