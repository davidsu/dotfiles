#!/usr/bin/env bun

import { execSync } from 'child_process'
import fs from 'fs'
import path from 'path'
import { log } from './logging'
import { removeDotConfigWithMiseOnlyIfExists } from './symlink/file-ops'
import { safeLink } from './symlink/operation'
import type { LinkResult } from './symlink/operation'

const GIT_ROOT = execSync('git rev-parse --show-toplevel', { encoding: 'utf-8' }).trim()
const HOME = process.env.HOME!

const expandHome = (target: string) => target.replace(/^~/, HOME)

function loadLinkMap() {
  const toml = fs.readFileSync(path.join(GIT_ROOT, 'links.toml'), 'utf-8')
  const parsed = Bun.TOML.parse(toml) as { links: Record<string, string[]> }
  return parsed.links
}

// Flatten the map into [source, target] pairs with resolved absolute paths
const buildSymlinkPlan = (linkMap: Record<string, string[]>) =>
  Object.entries(linkMap).flatMap(([repoPath, targets]) => {
    const from = path.join(GIT_ROOT, repoPath)
    return targets.map(target => ({ from, to: expandHome(target) }))
  })

// .map() causes side effects: creates symlinks, backs up existing files
const executeSymlinkPlan = (plan: { from: string; to: string }[]) =>
  plan.map(({ from, to }) => safeLink(from, to))

function setupSymlinks() {
  log.info('Starting symlinking process...')

  removeDotConfigWithMiseOnlyIfExists()
  const linkMap = loadLinkMap()
  const plan = buildSymlinkPlan(linkMap)

  log.info(`Found ${plan.length} symlinks in links.toml`)
  return executeSymlinkPlan(plan)
}

// Run if executed directly
if (import.meta.main) {
  const results = setupSymlinks()
  const failedCount = results.filter(r => !r.success).length

  if (failedCount > 0) {
    log.error('Symlinking process completed with errors.')
    process.exit(1)
  } else {
    log.success('Symlinking process completed successfully.')
  }
}

export { setupSymlinks }
export type { LinkResult }
