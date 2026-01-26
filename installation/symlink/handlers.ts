import fs from 'fs'
import { log } from '../logging'
import { backupFile } from './file-ops'

export function handleExistingSymlink(src: string, dest: string) {
  const currentLink = fs.readlinkSync(dest)
  if (currentLink === src) {
    log.success(`Link already exists: ${dest} -> ${src}`)
    return true
  }

  log.warn(`Existing link ${dest} points to ${currentLink}. Backing up...`)
  try {
    backupFile(dest)
    return false
  } catch (error) {
    log.error(`Failed to back up existing link: ${dest}`)
    return true
  }
}

export function handleExistingFile(dest: string) {
  log.warn(`Existing file ${dest} found. Backing up to ${dest}.bak`)
  try {
    backupFile(dest)
    return true
  } catch (error) {
    log.error(`Failed to back up existing file: ${dest}`)
    return false
  }
}

export function createLink(src: string, dest: string) {
  try {
    fs.symlinkSync(src, dest)
    log.success(`Created link: ${dest} -> ${src}`)
    return true
  } catch (error) {
    log.error(`Failed to create link: ${dest} -> ${src}`)
    return false
  }
}
