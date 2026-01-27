#!/usr/bin/env bun

import { execSync, spawn } from 'child_process'
import { existsSync } from 'fs'
import path from 'path'
import { homedir } from 'os'
import { log } from './logging'
import { isMacOS, getMacOSVersion, hasCommand } from './system'
import { loadTools, installTool } from './tools'
import { verifyAllTools } from './verify'
import { applyMacOSDefaults } from './macos-defaults'
import { setupSymlinks } from './links'
import type { LinkResult } from './links'

interface InstallResult {
  name: string
  success: boolean
  alreadyInstalled: boolean
}

function checkMacOS() {
  log.info('Running pre-flight checks...')

  if (!isMacOS()) {
    log.error('This dotfiles configuration is macOS-only. Exiting.')
    process.exit(1)
  }

  log.success(`macOS detected (v${getMacOSVersion()})`)
  log.info('Logs will be written to ~/Library/Logs/dotfiles/')
}

function installNode() {
  if (hasCommand('node')) {
    log.success('Node.js is already installed')
    return
  }

  log.info('Installing Node.js via mise...')
  execSync('mise use --global node@lts', { stdio: 'inherit' })
}

function trustMiseConfig() {
  const miseConfig = path.join(homedir(), '.config', 'mise', 'config.toml')

  if (!existsSync(miseConfig) || !hasCommand('mise')) return

  log.info('Trusting mise configuration...')
  execSync(`mise trust "${miseConfig}"`, { stdio: 'inherit' })
}

function installNeovimPluginsAsync() {
  if (!hasCommand('nvim')) return Promise.resolve()

  log.info('Installing Neovim plugins (running in background)...')

  return new Promise<void>((resolve, reject) => {
    const child = spawn('nvim', ['--headless', '+Lazy! sync', '+qa'], { stdio: 'inherit' })

    child.on('close', (code) => {
      if (code === 0) {
        log.success('Neovim plugins installed')
        resolve()
      } else {
        log.error('Neovim plugins installation failed')
        reject(new Error(`nvim exited with code ${code}`))
      }
    })

    child.on('error', (err) => {
      log.error(`Neovim plugins error: ${err.message}`)
      reject(err)
    })
  })
}

function installTools(tools: Record<string, unknown>) {
  const results: InstallResult[] = []
  for (const [name, tool] of Object.entries(tools)) {
    results.push(installTool(name, tool as Parameters<typeof installTool>[1]))
  }
  return results
}

function omit<T extends Record<string, unknown>>(obj: T, key: string) {
  const { [key]: _, ...rest } = obj
  return rest
}

function displaySummary(symlinkResults: LinkResult[], failedPackages: string[]) {
  console.log('')
  console.log('============================================================')

  const failedSymlinks = symlinkResults.filter((r) => !r.success)
  const successfulSymlinks = symlinkResults.filter((r) => r.success && !r.alreadyExists)
  const existingSymlinks = symlinkResults.filter((r) => r.alreadyExists)

  if (failedSymlinks.length > 0) {
    log.error(`${failedSymlinks.length} symlink(s) failed:`)
    for (const link of failedSymlinks) {
      log.error(`  ✗ ${link.to}`)
    }
  }

  if (successfulSymlinks.length > 0) {
    log.success(`${successfulSymlinks.length} symlink(s) created`)
  }

  if (existingSymlinks.length > 0) {
    log.info(`${existingSymlinks.length} symlink(s) already existed`)
  }

  console.log('------------------------------------------------------------')

  if (failedPackages.length > 0) {
    log.warn(`${failedPackages.length} package(s) failed:`)
    for (const pkg of failedPackages) {
      log.error(`  ✗ ${pkg}`)
    }
    log.info('Retry with: bun installation/install.ts')
  } else {
    log.success('All packages verified')
  }

  console.log('============================================================')
  console.log('')
  log.banner('MANUAL STEPS REQUIRED - See README.md → Post-install manual steps')
}

async function main() {
  log.info(`Starting dotfiles installation from ${import.meta.dir}...`)

  checkMacOS()

  // Load tools and separate neovim for dependency tracking
  const allTools = await loadTools()
  const neovimTool = allTools.neovim
  const otherTools = omit(allTools, 'neovim')

  // Phase 1: Fast operations (run first, they're quick)
  log.info('Phase 1: Quick setup tasks...')
  const symlinkResults = setupSymlinks()
  installNode()
  log.info('Applying macOS defaults...')
  applyMacOSDefaults()

  // Phase 2: Install neovim first (needed for plugins)
  log.info('Phase 2: Installing neovim...')
  const neovimResult = installTool('neovim', neovimTool)

  // Phase 3: Neovim plugins + remaining brew installs in parallel
  // spawn() runs nvim as separate process while brew installs continue
  log.info('Phase 3: Installing neovim plugins + remaining tools in parallel...')

  const neovimPluginsPromise = installNeovimPluginsAsync()

  // Continue with other brew installs (sequential, brew limitation)
  const otherToolsResults = installTools(otherTools)

  // Wait for neovim plugins to finish (likely already done by now)
  await neovimPluginsPromise

  // Combine tool results for reporting
  const allToolResults = [neovimResult, ...otherToolsResults]
  const failedInstalls = allToolResults.filter((r) => !r.success)
  if (failedInstalls.length === 0) {
    log.success('All packages installed successfully')
  } else {
    log.warn(`${failedInstalls.length} package(s) failed to install`)
  }

  // Trust mise config (needs symlinks done)
  trustMiseConfig()

  // Verification
  const failedPackages = await verifyAllTools()

  displaySummary(symlinkResults, failedPackages)
}

main()
