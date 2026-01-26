#!/usr/bin/env bun

import { execSync } from 'child_process'
import { log } from './logging'
import { getBrewfilePath } from './system'

function runBrewBundleCheck(brewfilePath: string) {
  try {
    execSync(`brew bundle check --file="${brewfilePath}"`, { stdio: 'ignore' })
    return true
  } catch {
    return false
  }
}

function showMissingPackages(brewfilePath: string) {
  execSync(`brew bundle check --file="${brewfilePath}"`, { stdio: 'inherit' })
}

export function verifyAllTools() {
  const brewfilePath = getBrewfilePath()

  log.info('Verifying all packages are installed...')

  if (runBrewBundleCheck(brewfilePath)) {
    log.success('All packages verified.')
    return
  }

  log.warn('Some packages failed to install:')
  showMissingPackages(brewfilePath)
  log.info('You can retry failed packages with: brew bundle --file=installation/Brewfile')
}
