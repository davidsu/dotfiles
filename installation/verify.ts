#!/usr/bin/env bun

import { log } from './logging'
import { loadTools, verifyTool } from './tools'

export async function verifyAllTools() {
  log.info('Verifying all packages are installed...')

  const tools = await loadTools()
  const failed: string[] = []

  for (const [name, tool] of Object.entries(tools)) {
    if (!verifyTool(name, tool)) {
      failed.push(name)
    }
  }

  if (failed.length === 0) {
    log.success('All packages verified')
    return
  }

  log.warn('Some packages failed verification:')
  for (const name of failed) {
    log.error(`  - ${name}`)
  }
  log.info('You can retry with: bun installation/install.ts')
}
