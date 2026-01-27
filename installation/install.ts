#!/usr/bin/env bun

import { spawn } from 'child_process'
import { log } from './logging'
import { isMacOS, getMacOSVersion, hasCommand } from './system'
import { loadTools, installTool, getToolsByType, installAllTaps, batchInstall, runCaskPostInstall } from './tools'
import { verifyAllTools } from './verify'
import { applyMacOSDefaults } from './macos-defaults'
import { setupSymlinks } from './links'
import type { LinkResult } from './links'

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
  if (!hasCommand('fnm')) {
    log.warn('fnm not installed yet, skipping Node.js installation')
    return
  }
  log.info('Installing Node.js via fnm (background)...')
  spawn('fnm', ['install', '--lts'], { stdio: 'inherit' })
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

  // Load and categorize tools
  const allTools = await loadTools()
  const { formulas, casks, taps } = getToolsByType(allTools)
  const formulasWithoutNeovim = formulas.filter((f) => f !== 'neovim')

  // Phase 1: Quick setup
  log.info('Phase 1: Quick setup tasks...')
  const symlinkResults = setupSymlinks()
  log.info('Applying macOS defaults...')
  applyMacOSDefaults()

  // Phase 2: Install all taps
  log.info('Phase 2: Installing taps...')
  installAllTaps(taps)

  // Phase 3: Batch install all casks, then open GUI apps
  log.info('Phase 3: Installing casks (parallel fetch, then install)...')
  await batchInstall(casks, 'cask')
  log.info('Opening GUI apps that need setup...')
  runCaskPostInstall(allTools)

  // Phase 4: Install neovim (needed for plugins)
  log.info('Phase 4: Installing neovim...')
  installTool('neovim', allTools.neovim)

  // Phase 5: Neovim plugins + remaining formulas in parallel
  log.info('Phase 5: Installing neovim plugins + remaining formulas in parallel...')
  const neovimPluginsPromise = installNeovimPluginsAsync()
  const formulasPromise = batchInstall(formulasWithoutNeovim, 'formula')
  await Promise.all([neovimPluginsPromise, formulasPromise])

  // Phase 6: Install Node.js via fnm (now that fnm is installed)
  log.info('Phase 6: Installing Node.js...')
  installNode()

  // Verification
  const failedPackages = await verifyAllTools()

  displaySummary(symlinkResults, failedPackages)
}

main()
