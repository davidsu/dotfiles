#!/usr/bin/env bun

import { execSync } from 'child_process'
import { existsSync } from 'fs'
import path from 'path'
import { homedir } from 'os'
import { log } from './logging'
import { isMacOS, getMacOSVersion, hasCommand } from './system'
import { installAllTools } from './tools'
import { verifyAllTools } from './verify'
import { applyMacOSDefaults } from './macos-defaults'
import { setupSymlinks } from './links'
import type { LinkResult } from './links'

function installNode() {
  if (hasCommand('node')) return

  log.info('Installing Node.js via mise...')
  execSync('mise use --global node@lts', { stdio: 'inherit' })
}

async function installDependencies() {
  installNode()

  log.info('Installing packages from tools.yaml...')
  const results = await installAllTools()

  const failed = results.filter((r) => !r.success)
  if (failed.length === 0) {
    log.success('All packages installed successfully')
  } else {
    log.warn(`${failed.length} package(s) failed to install`)
    log.info('Failed packages will be reported during verification step')
  }
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

function symlinkDotfiles(): LinkResult[] {
  return setupSymlinks()
}

function trustMiseConfig() {
  const miseConfig = path.join(homedir(), '.config', 'mise', 'config.toml')

  if (!existsSync(miseConfig) || !hasCommand('mise')) return

  log.info('Trusting mise configuration...')
  execSync(`mise trust "${miseConfig}"`, { stdio: 'inherit' })
}

function installNeovimPlugins() {
  if (!hasCommand('nvim')) return

  log.info('Installing Neovim plugins (this may take a minute)...')
  execSync('nvim --headless "+Lazy! sync" +qa', { stdio: 'inherit' })
  log.success('Neovim plugins installed')
}

function runPostInstallSteps() {
  log.info('Running post-installation configurations...')
  trustMiseConfig()
  log.info('Applying macOS defaults...')
  applyMacOSDefaults()
  installNeovimPlugins()
}

async function main() {
  log.info(`Starting dotfiles installation from ${import.meta.dir}...`)

  checkMacOS()
  await installDependencies()
  const symlinkResults = symlinkDotfiles()
  const failedPackages = await verifyAllTools()
  runPostInstallSteps()

  // Display summary
  console.log('')
  console.log('============================================================')

  // Symlink results
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

  // Package results
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

main()
