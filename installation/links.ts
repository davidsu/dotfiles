#!/usr/bin/env bun

/**
 * Symlinking Logic for Dotfiles
 * Handles linking all .symlink files to their target locations
 */

import { execSync } from 'child_process'
import fs from 'fs'
import path from 'path'

// Configuration
const SCRIPT_DIR = import.meta.dir
const DOTFILES_ROOT = path.dirname(SCRIPT_DIR)
const LOGGING_SCRIPT = path.join(SCRIPT_DIR, 'logging.sh')

// Types
type LogLevel = 'info' | 'success' | 'warn' | 'error'

// Logging helpers
const createLogFunction = (level: LogLevel) => (msg: string) => {
  execSync(`source "${LOGGING_SCRIPT}" && log_${level} '${msg}'`, {
    stdio: 'inherit',
    shell: '/bin/bash'
  })
}

const log = {
  info: createLogFunction('info'),
  success: createLogFunction('success'),
  warn: createLogFunction('warn'),
  error: createLogFunction('error')
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

// Handle edge case: mise creates ~/.config before symlinks run
function handleConfigEdgeCase() {
  const configPath = path.join(process.env.HOME!, '.config')

  if (isSymlink(configPath)) return

  const contents = fs.readdirSync(configPath).filter((f) => !f.startsWith('.'))
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

function safeLink(src: string, dest: string) {
  // Handle existing symlink
  if (isSymlink(dest)) {
    const shouldStop = handleExistingSymlink(src, dest)
    if (shouldStop) return true
  }

  // Handle existing file
  if (fileExists(dest)) {
    if (!handleExistingFile(dest)) return false
  }

  // Create parent directory and link
  fs.mkdirSync(path.dirname(dest), { recursive: true })
  return createLink(src, dest)
}

function findSymlinkFiles(rootDir: string) {
  const output = execSync(`find . -name '*.symlink*' \\( -type f -o -type d \\)`, {
    cwd: rootDir,
    encoding: 'utf-8'
  })

  return output
    .trim()
    .split('\n')
    .filter((line) => line.length > 0)
    .map((file) => path.join(rootDir, file))
}

function linkHomeFiles() {
  log.info(`Finding .home.* files in ${DOTFILES_ROOT}...`)

  const symlinkFiles = findSymlinkFiles(DOTFILES_ROOT)
  let failedCount = 0

  for (const src of symlinkFiles) {
    const filename = path.basename(src)
    const dest = transformPath(filename)

    if (dest) {
      if (!safeLink(src, dest)) {
        failedCount++
      }
    } else {
      log.warn(`Could not parse filename pattern: ${filename}`)
    }
  }

  return failedCount
}

function setupSymlinks() {
  log.info('Starting symlinking process...')

  handleConfigEdgeCase()
  const failedCount = linkHomeFiles()

  if (failedCount > 0) {
    log.error('Symlinking process completed with errors.')
    process.exit(1)
  } else {
    log.success('Symlinking process completed successfully.')
  }
}

// Run if executed directly
if (import.meta.main) {
  setupSymlinks()
}

export { setupSymlinks, safeLink, transformPath }
