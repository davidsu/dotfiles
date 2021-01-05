import { existsSync } from 'fs'
import path from 'path'
import os from 'os'
const nvimConfigDir = path.join(os.homedir(), '.dotfiles/config/nvim')
function getRoot(directory, isRoot) {
  if (!directory || directory === '/' || directory === os.homedir()) {
    return ''
  }
  if (isRoot(directory)) {
    return directory
  }
  return getRoot(path.dirname(directory), isRoot)
}

const isGitRoot = dir => existsSync(path.join(dir, '.git'))
export const getProjectRoot = dir => getRoot(dir, p => existsSync(path.join(p, 'package.json')) || p === nvimConfigDir)
export const getGitRoot = dir => getRoot(dir, isGitRoot)
