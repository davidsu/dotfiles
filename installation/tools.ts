#!/usr/bin/env bun

import { execSync } from 'child_process'
import path from 'path'
import { log } from './logging'

function getToolsPath() {
  return path.join(import.meta.dir, 'tools.yaml')
}

type BrewType = 'formula' | 'cask'

interface Tool {
  brew_type: BrewType
  cmd?: string
  tap?: string
  description: string
}

interface InstallResult {
  name: string
  success: boolean
  alreadyInstalled: boolean
}

export async function loadTools() {
  const toolsPath = getToolsPath()
  const content = await Bun.file(toolsPath).text()
  const parsed = Bun.YAML.parse(content) as { tools: Record<string, Tool> }
  return parsed.tools
}

function isInstalled(name: string, brewType: BrewType) {
  try {
    const flag = brewType === 'cask' ? '--cask' : '--formula'
    execSync(`brew list ${flag} ${name}`, { stdio: 'ignore' })
    return true
  } catch {
    return false
  }
}

function isTapInstalled(tap: string) {
  try {
    const taps = execSync('brew tap', { encoding: 'utf-8' })
    return taps.split('\n').includes(tap)
  } catch {
    return false
  }
}

function installTap(tap: string) {
  if (isTapInstalled(tap)) {
    return true
  }

  try {
    execSync(`brew tap ${tap}`, { stdio: 'inherit' })
    return true
  } catch {
    log.warn(`Failed to tap ${tap}`)
    return false
  }
}

function removeQuarantineFromCask(caskName: string) {
  try {
    const info = execSync(`brew info --cask ${caskName} --json`, { encoding: 'utf-8' })
    const parsed = JSON.parse(info)
    const artifacts = parsed[0]?.artifacts

    if (!artifacts) return

    // Find .app artifacts
    for (const artifact of artifacts) {
      if (artifact.app) {
        const appNames = Array.isArray(artifact.app) ? artifact.app : [artifact.app]
        for (const appName of appNames) {
          const appPath = `/Applications/${appName}`
          execSync(`xattr -dr com.apple.quarantine "${appPath}" 2>/dev/null || true`, { stdio: 'ignore' })
        }
      }
    }
  } catch {
    // Silently fail - app info might not be available or already unquarantined
  }
}

function installPackage(name: string, brewType: BrewType): boolean {
  try {
    const flag = brewType === 'cask' ? '--cask' : ''
    execSync(`brew install ${flag} ${name} < /dev/null`, { stdio: 'inherit' })

    if (brewType === 'cask') {
      removeQuarantineFromCask(name)
    }

    return true
  } catch {
    return false
  }
}

export function installTool(name: string, tool: Tool): InstallResult {
  if (isInstalled(name, tool.brew_type)) {
    log.success(`${name} is already installed`)
    return { name, success: true, alreadyInstalled: true }
  }

  if (tool.tap) {
    installTap(tool.tap)
  }

  log.info(`Installing ${name} (${tool.brew_type})...`)
  const success = installPackage(name, tool.brew_type)

  if (success) {
    log.success(`Installed ${name}`)
  } else {
    log.error(`Failed to install ${name}`)
  }

  return { name, success, alreadyInstalled: false }
}

export async function installAllTools() {
  const tools = await loadTools()
  const results: InstallResult[] = []

  for (const [name, tool] of Object.entries(tools)) {
    results.push(installTool(name, tool))
  }

  return results
}

export function verifyTool(name: string, tool: Tool): boolean {
  const commandName = tool.cmd || name

  try {
    execSync(`command -v ${commandName}`, { stdio: 'ignore' })
    return true
  } catch {
    if (tool.brew_type === 'cask') {
      return isInstalled(name, 'cask')
    }
    return false
  }
}
