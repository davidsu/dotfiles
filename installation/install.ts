#!/usr/bin/env bun

import { execSync } from 'child_process'
import { existsSync } from 'fs'
import path from 'path'
import { homedir } from 'os'
import { log } from './logging'
import { isMacOS, getMacOSVersion, hasCommand, getBrewfilePath } from './system'
import { verifyAllTools } from './verify'
import { applyMacOSDefaults } from './macos-defaults'

function installNode() {
  if (hasCommand('node')) return

  log.info('Installing Node.js via mise...')
  execSync('mise use --global node@lts', { stdio: 'inherit' })
}

function installDependencies() {
  installNode()

  const brewfilePath = getBrewfilePath()
  log.info('Installing packages via brew bundle...')
  execSync(`brew bundle --no-upgrade --verbose --file="${brewfilePath}"`, { stdio: 'inherit' })
  log.success('All packages installed.')
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

function symlinkDotfiles() {
  const linksScript = path.join(import.meta.dir, 'links.ts')
  execSync(`bun ${linksScript}`, { stdio: 'inherit' })
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

function main() {
  log.info(`Starting dotfiles installation from ${import.meta.dir}...`)

  checkMacOS()
  installDependencies()
  symlinkDotfiles()
  verifyAllTools()
  runPostInstallSteps()

  log.success('Installation and verification completed successfully.')
  log.banner('MANUAL STEPS REQUIRED - See README.md → Post-install manual steps')
}

main()
