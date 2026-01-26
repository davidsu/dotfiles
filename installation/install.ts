#!/usr/bin/env bun

import { execSync } from 'child_process'
import { existsSync } from 'fs'
import path from 'path'
import { homedir } from 'os'
import { logInfo, logSuccess, logError, logBanner } from './logging'
import { isMacOS, getMacOSVersion, hasCommand, getBrewfilePath } from './system'
import { verifyAllTools } from './verify'
import { applyMacOSDefaults } from './macos-defaults'

function installNode() {
  if (hasCommand('node')) return

  logInfo('Installing Node.js via mise...')
  execSync('mise use --global node@lts', { stdio: 'inherit' })
}

function installDependencies() {
  installNode()

  const brewfilePath = getBrewfilePath()
  logInfo('Installing packages via brew bundle...')
  execSync(`brew bundle --no-upgrade --file="${brewfilePath}"`, { stdio: 'inherit' })
  logSuccess('All packages installed.')
}

function checkMacOS() {
  logInfo('Running pre-flight checks...')

  if (!isMacOS()) {
    logError('This dotfiles configuration is macOS-only. Exiting.')
    process.exit(1)
  }

  logSuccess(`macOS detected (v${getMacOSVersion()})`)
  logInfo('Logs will be written to ~/Library/Logs/dotfiles/')
}

function symlinkDotfiles() {
  const linksScript = path.join(import.meta.dir, 'links.ts')
  execSync(`bun ${linksScript}`, { stdio: 'inherit' })
}

function trustMiseConfig() {
  const miseConfig = path.join(homedir(), '.config', 'mise', 'config.toml')

  if (!existsSync(miseConfig) || !hasCommand('mise')) return

  logInfo('Trusting mise configuration...')
  execSync(`mise trust "${miseConfig}"`, { stdio: 'inherit' })
}

function installNeovimPlugins() {
  if (!hasCommand('nvim')) return

  logInfo('Installing Neovim plugins (this may take a minute)...')
  execSync('nvim --headless "+Lazy! sync" +qa', { stdio: 'inherit' })
  logSuccess('Neovim plugins installed')
}

function runPostInstallSteps() {
  logInfo('Running post-installation configurations...')
  trustMiseConfig()
  logInfo('Applying macOS defaults...')
  applyMacOSDefaults()
  installNeovimPlugins()
}

function main() {
  logInfo(`Starting dotfiles installation from ${import.meta.dir}...`)

  checkMacOS()
  installDependencies()
  symlinkDotfiles()
  verifyAllTools()
  runPostInstallSteps()

  logSuccess('Installation and verification completed successfully.')
  logBanner('MANUAL STEPS REQUIRED - See README.md → Post-install manual steps')
}

if (import.meta.main) {
  main()
}
