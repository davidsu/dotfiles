#!/usr/bin/env bun

import { execSync, spawn } from 'child_process'
import { RED, GREEN, YELLOW, colorize } from './logging'
import { hasCommand } from './system'

const VM_NAME = 'dotfiles-test'
const MACOS_IMAGE = 'ghcr.io/cirruslabs/macos-sonoma-vanilla:latest'
const VM_DISK_SIZE = 50
const VM_MEMORY = 8
const SSH_RETRY_INTERVAL_MS = 5000
const SSH_MAX_RETRIES = 60
const VM_USER = 'admin'
const VM_PASSWORD = 'admin'

const log = (message: string) => console.log(colorize(GREEN, `[TEST] ${message}`))
const warn = (message: string) => console.log(colorize(YELLOW, `[WARN] ${message}`))

function error(message: string): never {
  console.error(colorize(RED, `[ERROR] ${message}`))
  process.exit(1)
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

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

function deleteExistingVM() {
  if (!vmExists()) return
  log('Deleting existing VM...')
  execSync(`tart stop ${VM_NAME} 2>/dev/null || true`, { stdio: 'inherit' })
  execSync(`tart delete ${VM_NAME}`, { stdio: 'inherit' })
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

function getVMIP() {
  const output = execSync(`tart ip ${VM_NAME}`, { encoding: 'utf-8' })
  return output.trim()
}

function ensureSshpass() {
  if (hasCommand('sshpass')) return

  warn('sshpass not found. Installing via Homebrew...')
  execSync('brew install hudochenkov/sshpass/sshpass', { stdio: 'inherit' })
}

function sshCommand(ip: string, cmd: string) {
  return `sshpass -p '${VM_PASSWORD}' ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${VM_USER}@${ip} "${cmd}"`
}

function trySSHConnection(ip: string) {
  try {
    execSync(sshCommand(ip, 'echo connected'), { encoding: 'utf-8', stdio: 'pipe' })
    return true
  } catch {
    return false
  }
}

async function waitForSSH() {
  ensureSshpass()
  log('Waiting for VM to boot and SSH to become available...')

  for (let attempt = 1; attempt <= SSH_MAX_RETRIES; attempt++) {
    try {
      const ip = getVMIP()
      if (trySSHConnection(ip)) {
        log(`SSH connection established to ${ip}`)
        return ip
      }
    } catch {
      // VM IP not available yet
    }

    process.stdout.write(`\r[TEST] Attempt ${attempt}/${SSH_MAX_RETRIES} - waiting for SSH...`)
    await sleep(SSH_RETRY_INTERVAL_MS)
  }

  console.log('')
  error('SSH connection timeout. VM may not have booted properly.')
}

function runBootstrapViaSSH(ip: string) {
  const bootstrapURL = getBootstrapURL()
  const bootstrapCommand = `/bin/bash -c "$(curl -fsSL ${bootstrapURL})"`

  log('Running bootstrap script via SSH...')
  log(`Command: ${bootstrapCommand}`)

  execSync(`sshpass -p '${VM_PASSWORD}' ssh -o StrictHostKeyChecking=no ${VM_USER}@${ip} '${bootstrapCommand}'`, {
    stdio: 'inherit'
  })
}

function startVMInBackground() {
  log('Starting VM in background...')
  const child = spawn('tart', ['run', VM_NAME], {
    detached: true,
    stdio: 'ignore'
  })
  child.unref()
  log('VM started')
}

async function main() {
  ensureTart()
  deleteExistingVM()
  cloneVM()
  configureVM()
  startVMInBackground()
  const ip = await waitForSSH()
  runBootstrapViaSSH(ip)
  log('Installation complete!')
  log('When done, delete the VM:')
  console.log(`   tart delete ${VM_NAME}`)
}

if (import.meta.main) {
  main()
}
