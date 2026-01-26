#!/usr/bin/env bun

import { execSync } from 'child_process'
import fs from 'fs'
import path from 'path'
import { log } from './logging'

const SCRIPT_DIR = import.meta.dir
const DOTFILES_ROOT = path.dirname(SCRIPT_DIR)

interface SymlinkPlan {
  from: string
  to: string | null
}

interface LinkResult {
  from: string
  to: string
  success: boolean
  alreadyExists: boolean
}

// Path transformation logic
const extractExtension = (filename: string) => filename.replace(/.*symlink/, '')

const removeSymlinkAndExtension = (filename: string) => filename.replace(/\.symlink.*$/, '')

const replaceDOTWithDot = (str: string) => str.replace(/DOT/g, '.')

const removeLeadingDot = (str: string) => str.replace(/^\./, '')

const transformPathToDirectory = (pathPart: string) =>
  pathPart ? '/' + pathPart.replace(/\./g, '/').replace(/DOT/g, '.') : ''

function transformPath(filename: string) {
  if (!/\.home/.test(filename)) return null

  const extension = extractExtension(filename)
  const base = removeSymlinkAndExtension(filename)
  const [namePart, ...rest] = base.split('.home')
  const name = replaceDOTWithDot(namePart)
  const pathPart = removeLeadingDot(rest.join('.home'))
  const directory = transformPathToDirectory(pathPart)

  return `${process.env.HOME}${directory}/${name}${extension}`
}

// Remove ~/.config if it only contains mise/ (created during mise bootstrap)
function removeDotConfigWithMiseOnly() {
  const configPath = path.join(process.env.HOME!, '.config')

  if (!fs.existsSync(configPath)) return
  if (isSymlink(configPath)) return

  const contents = fs.readdirSync(configPath).filter((f: string) => !f.startsWith('.'))
  if (contents.length === 1 && contents[0] === 'mise') {
    log.info('~/.config only contains mise/, removing to allow symlink...')
    fs.rmSync(configPath, { recursive: true })
  }
}

// File operations
function isSymlink(filePath: string) {
  try {
    return fs.lstatSync(filePath).isSymbolicLink()
  } catch {
    return false
  }
}

function fileExists(filePath: string) {
  try {
    fs.accessSync(filePath)
    return true
  } catch {
    return false
  }
}

function backupFile(filePath: string) {
  const backupPath = `${filePath}.bak`
  fs.renameSync(filePath, backupPath)
}

// Core symlinking logic
function handleExistingSymlink(src: string, dest: string) {
  const currentLink = fs.readlinkSync(dest)
  if (currentLink === src) {
    log.success(`Link already exists: ${dest} -> ${src}`)
    return true
  }

  log.warn(`Existing link ${dest} points to ${currentLink}. Backing up...`)
  try {
    backupFile(dest)
    return false // Continue with link creation
  } catch (error) {
    log.error(`Failed to back up existing link: ${dest}`)
    return true // Stop processing
  }
}

function handleExistingFile(dest: string) {
  log.warn(`Existing file ${dest} found. Backing up to ${dest}.bak`)
  try {
    backupFile(dest)
    return true // Success, continue
  } catch (error) {
    log.error(`Failed to back up existing file: ${dest}`)
    return false // Failed, stop
  }
}

function createLink(src: string, dest: string) {
  try {
    fs.symlinkSync(src, dest)
    log.success(`Created link: ${dest} -> ${src}`)
    return true
  } catch (error) {
    log.error(`Failed to create link: ${dest} -> ${src}`)
    return false
  }
}

function safeLink(src: string, dest: string): LinkResult {
  // Handle existing symlink
  if (isSymlink(dest)) {
    const shouldStop = handleExistingSymlink(src, dest)
    if (shouldStop) return { from: src, to: dest, success: true, alreadyExists: true }
  }

  // Handle existing file
  if (fileExists(dest)) {
    if (!handleExistingFile(dest)) return { from: src, to: dest, success: false, alreadyExists: false }
  }

  // Create parent directory and link
  fs.mkdirSync(path.dirname(dest), { recursive: true })
  const success = createLink(src, dest)
  return { from: src, to: dest, success, alreadyExists: false }
}

function findSymlinkFiles(rootDir: string): string[] {
  const output = execSync(`find . -name '*.symlink*' \\( -type f -o -type d \\)`, {
    cwd: rootDir,
    encoding: 'utf-8'
  })

  return output
    .trim()
    .split('\n')
    .filter((line: string) => line.length > 0)
    .map((file: string) => path.join(rootDir, file))
}

function buildSymlinkPlan() {
  const symlinkFiles = findSymlinkFiles(DOTFILES_ROOT)

  return symlinkFiles.map(src => {
    const filename = path.basename(src)
    const dest = transformPath(filename)

    if (!dest) {
      log.warn(`Could not parse filename pattern: ${filename}`)
    }

    return { from: src, to: dest }
  })
}

function executeSymlinkPlan(plan: SymlinkPlan[]): LinkResult[] {
  const results: LinkResult[] = []

  for (const { from, to } of plan) {
    if (to) {
      results.push(safeLink(from, to))
    }
  }

  return results
}

function setupSymlinks(): LinkResult[] {
  log.info('Starting symlinking process...')
  log.info(`Finding .home.* files in ${DOTFILES_ROOT}...`)

  removeDotConfigWithMiseOnly()
  const plan = buildSymlinkPlan()
  const results = executeSymlinkPlan(plan)

  return results
}

// Run if executed directly
if (import.meta.main) {
  const results = setupSymlinks()
  const failedCount = results.filter((r) => !r.success).length

  if (failedCount > 0) {
    log.error('Symlinking process completed with errors.')
    process.exit(1)
  } else {
    log.success('Symlinking process completed successfully.')
  }
}

export { setupSymlinks, buildSymlinkPlan, safeLink, transformPath }
export type { SymlinkPlan, LinkResult }
