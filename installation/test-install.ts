#!/usr/bin/env bun

import { execSync } from 'child_process'
import { RED, GREEN, YELLOW, colorize } from './logging'
import { hasCommand } from './system'

const VM_NAME = 'dotfiles-test'
const MACOS_IMAGE = 'ghcr.io/cirruslabs/macos-sonoma-vanilla:latest'
const VM_DISK_SIZE = 50
const VM_MEMORY = 8

function log(message: string) {
  console.log(colorize(GREEN, `[TEST] ${message}`))
}

function warn(message: string) {
  console.log(colorize(YELLOW, `[WARN] ${message}`))
}

function error(message: string) {
  console.error(colorize(RED, `[ERROR] ${message}`))
  process.exit(1)
}

function installTart() {
  warn('Tart is not installed. Installing via Homebrew...')

  if (!hasCommand('brew')) {
    error('Homebrew is not installed. Install from https://brew.sh')
  }

  log('Running: brew install cirruslabs/cli/tart')
  execSync('brew install cirruslabs/cli/tart', { stdio: 'inherit' })

  if (!hasCommand('tart')) {
    error('Failed to install tart')
  }

  log('Tart installed successfully')
}

function ensureTart() {
  if (hasCommand('tart')) return
  installTart()
}

function vmExists() {
  const output = execSync('tart list', { encoding: 'utf-8' })
  return output.includes(`\n${VM_NAME}\t`) || output.startsWith(`${VM_NAME}\t`)
}

function promptDeleteVM() {
  warn(`VM '${VM_NAME}' already exists`)

  const answer = prompt('Delete and recreate? (y/N): ')
  if (answer?.toLowerCase() === 'y') {
    log('Deleting existing VM...')
    execSync(`tart delete ${VM_NAME}`, { stdio: 'inherit' })
    return
  }

  error(`Aborted. Delete the VM manually with: tart delete ${VM_NAME}`)
}

function checkExistingVM() {
  if (!vmExists()) return
  promptDeleteVM()
}

function cloneVM() {
  log('Cloning macOS image (this may take a while on first run)...')
  execSync(`tart clone "${MACOS_IMAGE}" "${VM_NAME}"`, { stdio: 'inherit' })
}

function configureVM() {
  log(`Configuring VM (disk: ${VM_DISK_SIZE}GB, memory: ${VM_MEMORY}GB)...`)
  execSync(`tart set "${VM_NAME}" --disk-size ${VM_DISK_SIZE} --memory ${VM_MEMORY * 1024}`, {
    stdio: 'inherit'
  })
}

function getGitHubRepo() {
  const remoteUrl = execSync('git config --get remote.origin.url', { encoding: 'utf-8' }).trim()
  const match = remoteUrl.match(/github\.com[:/](.*)\.git/)
  return match ? match[1] : ''
}

function getBootstrapURL() {
  const repo = getGitHubRepo()
  return `https://raw.githubusercontent.com/${repo}/master/installation/bootstrap.sh`
}

function printInstructions() {
  const bootstrapURL = getBootstrapURL()

  log('VM created successfully: ' + VM_NAME)
  console.log('')
  log('Next steps:')
  console.log('')
  log('1. Start the VM:')
  console.log(`   tart run ${VM_NAME}`)
  console.log('')
  log('2. Wait for macOS to boot (first boot takes 2-3 minutes)')
  console.log('   A macOS window will open')
  console.log('')
  log('3. In the VM Terminal, run the bootstrap script:')
  console.log(`   curl -fsSL ${bootstrapURL} | bash`)
  console.log('   or ssh into the machine:')
  console.log(`   ssh admin@$(tart ip ${VM_NAME})`)
  console.log('')
  log('   Note: Bootstrap uses HTTPS (no SSH key needed for installation)')
  log('   The script will show instructions for switching to SSH afterward')
  console.log('')
  log('4. Test the installation:')
  console.log('   - Verify all tools installed: brew list')
  console.log('   - Check symlinks: ls -la ~ | grep \'^l\'')
  console.log('   - Test Neovim: nvim')
  console.log('   - Test aliases: jfzf, mru, etc.')
  console.log('')
  log('5. When done, delete the VM:')
  console.log(`   tart delete ${VM_NAME}`)
}

function main() {
  ensureTart()
  checkExistingVM()
  cloneVM()
  configureVM()
  printInstructions()
}

if (import.meta.main) {
  main()
}
