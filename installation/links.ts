#!/usr/bin/env bun

import { execSync } from 'child_process'
import path from 'path'
import { log } from './logging'
import { transformPath } from './symlink/path-transform'
import { removeDotConfigWithMiseOnlyIfExists } from './symlink/file-ops'
import { safeLink } from './symlink/operation'
import type { LinkResult } from './symlink/operation'

const GIT_ROOT = execSync('git rev-parse --show-toplevel', { encoding: 'utf-8' }).trim()

interface SymlinkPlan {
  from: string
  to: string | null
}

function findSymlinkFiles(rootDir: string) {
  const output = execSync(`find . -name '*.symlink*' \\( -type f -o -type d \\)`, {
    cwd: rootDir,
    encoding: 'utf-8'
  })

  return output
    .trim()
    .split('\n')
    .filter((line) => line.length > 0)
    .map((file) => path.join(rootDir, file))
}

function buildSymlinkPlan() {
  const symlinkFiles = findSymlinkFiles(GIT_ROOT)

  return symlinkFiles.map(src => {
    const filename = path.basename(src)
    const dest = transformPath(filename)

    if (!dest) {
      log.warn(`Could not parse filename pattern: ${filename}`)
    }

    return { from: src, to: dest }
  })
}

// .map() causes side effects: creates symlinks, backs up existing files
const executeSymlinkPlan = (plan: SymlinkPlan[]) =>
  plan.map(({ from, to }) => safeLink(from, to))

function setupSymlinks() {
  log.info('Starting symlinking process...')
  log.info(`Finding .home.* files in ${GIT_ROOT}...`)

  removeDotConfigWithMiseOnlyIfExists()
  const plan = buildSymlinkPlan()
  const results = executeSymlinkPlan(plan)

  return results
}

// Run if executed directly
if (import.meta.main) {
  const results = setupSymlinks()
  const failedCount = results.filter((r) => !r.success).length

  if (failedCount > 0) {
    log.error('Symlinking process completed with errors.')
    process.exit(1)
  } else {
    log.success('Symlinking process completed successfully.')
  }
}

export { setupSymlinks }
export type { LinkResult }
