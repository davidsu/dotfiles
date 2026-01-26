import fs from 'fs'
import path from 'path'
import { log } from '../logging'

export function isSymlink(filePath: string) {
  try {
    return fs.lstatSync(filePath).isSymbolicLink()
  } catch {
    return false
  }
}

export function fileExists(filePath: string) {
  try {
    fs.accessSync(filePath)
    return true
  } catch {
    return false
  }
}

export function backupFile(filePath: string) {
  const backupPath = `${filePath}.bak`
  fs.renameSync(filePath, backupPath)
}

export function removeDotConfigWithMiseOnlyIfExists() {
  const configPath = path.join(process.env.HOME!, '.config')

  if (!fs.existsSync(configPath)) return
  if (isSymlink(configPath)) return

  const contents = fs.readdirSync(configPath).filter((f: string) => !f.startsWith('.'))
  if (contents.length === 1 && contents[0] === 'mise') {
    log.info('~/.config only contains mise/, removing to allow symlink...')
    fs.rmSync(configPath, { recursive: true })
  }
}
