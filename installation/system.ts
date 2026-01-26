#!/usr/bin/env bun

import { execSync } from 'child_process'

export function isMacOS() {
  return process.platform === 'darwin'
}

export function hasCommand(command: string) {
  try {
    execSync(`command -v ${command}`, { stdio: 'ignore' })
    return true
  } catch {
    return false
  }
}

export function getMacOSVersion() {
  const output = execSync('sw_vers -productVersion', { encoding: 'utf-8' })
  return output.trim()
}
