import { debounce } from 'debounce'
import { commands, workspace } from 'coc.nvim'
import path from 'path'
import os from 'os'
import { existsSync, writeFileSync, readFileSync } from 'fs'

const { nvim } = workspace
const dirMap = path.join(os.homedir(), '.local', 'share', 'nvim', 'vimJsAutoCd.json')
const writeJsonSync = obj => writeFileSync(dirMap, JSON.stringify(obj))

let sessionSelectedDirectories: Array<string> = []

const nvimConfigDir = path.join(os.homedir(), '.dotfiles/config/nvim')
const getProjectsMap = () => JSON.parse(readFileSync(dirMap, { encoding: 'utf8' }))

async function CD(dir) {
  if (dir !== workspace.cwd) {
    nvim.command(`cd ${dir}`)
  }
}

async function isInvalidAutoCDBuffer() {
  const ft = await nvim.getOption('filetype')
  const currentDir = await getCurrentBufferPath()
  return ft === 'nerdtree' || !currentDir.startsWith('/')
}

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

const getProjectRoot = dir => getRoot(dir, p => existsSync(path.join(p, 'package.json')) || p === nvimConfigDir)
const getGitRoot = dir => getRoot(dir, isGitRoot)
const getCurrentBufferPath = () => nvim.callFunction('expand', '%:p:h')

module.exports = async () => {
  async function cdGitRoot() {
    if (await isInvalidAutoCDBuffer()) {
      //TODO warn(not git repo)
      return
    }
    const root = await getGitRoot(await getCurrentBufferPath())
    if (root) {
      CD(root)
      const projectsRootDicts = getProjectsMap()
      projectsRootDicts.roots[root] = true
      writeJsonSync(projectsRootDicts)
    }
  }

  async function cdProjectRoot() {
    if (await isInvalidAutoCDBuffer()) {
      //TODO command! CDC if &filetype == 'nerdtree' | execute 'cd /'.join(b:NERDTreeRoot.path.pathSegments, '/') | else | cd %:p:h | endif
      return
    }
    const currentBufferPath = await getCurrentBufferPath()
    const root = getProjectRoot(currentBufferPath)
    if (root) {
      CD(root)
      const projectsRootDicts = getProjectsMap()
      delete projectsRootDicts.roots[getGitRoot(currentBufferPath)]
      sessionSelectedDirectories = sessionSelectedDirectories.filter(a => !root.startsWith(a))
      writeJsonSync(projectsRootDicts)
    }
  }

  async function cdCurrentPath() {
    if (await isInvalidAutoCDBuffer()) {
      //TODO? if &filetype == 'nerdtree' | execute 'cd /'.join(b:NERDTreeRoot.path.pathSegments, '/') | else | cd %:p:h | endif
      return
    }
    const root = await getCurrentBufferPath()
    CD(root)
    const projectsRootDicts = getProjectsMap()
    delete projectsRootDicts.roots[getGitRoot(root)]
    sessionSelectedDirectories = sessionSelectedDirectories.filter(a => !a.startsWith(root))
    sessionSelectedDirectories.push(root)
    writeJsonSync(projectsRootDicts)
  }

  async function onChangeDirectory() {
    sessionSelectedDirectories = sessionSelectedDirectories.filter(a => !a.startsWith(workspace.cwd))
    const { cwd } = workspace
    if (!isGitRoot(cwd) && cwd !== '/' && cwd !== os.homedir()) {
      sessionSelectedDirectories.push(workspace.cwd)
    }
  }

  async function onBufferChange() {
    if (await isInvalidAutoCDBuffer()) return
    const currentDir = await getCurrentBufferPath()
    const projectsRootDicts = getProjectsMap()
    for (const path of [...sessionSelectedDirectories, ...Object.keys(projectsRootDicts.roots)].sort(
      (a, b) => b.length - a.length
    )) {
      if (currentDir.startsWith(path)) {
        CD(path)
        return
      }
    }
    onVimEnter()
  }

  async function onVimEnter() {
    if (!existsSync(dirMap)) {
      writeJsonSync({ roots: {} })
    }
    const projectsRootDicts = getProjectsMap()
    const currentDir = await getCurrentBufferPath()
    const gitRoot = getGitRoot(currentDir)
    const projectRoot = getProjectRoot(currentDir)
    if (projectRoot && gitRoot.startsWith(projectRoot as string)) {
      // looks like .../config/nvim/plugged/someproj
      return CD(gitRoot)
    }
    if (gitRoot in projectsRootDicts.roots) {
      return CD(gitRoot)
    }
    if (projectRoot) {
      return CD(projectRoot)
    }
    CD(currentDir)
  }
  const debouncedBufferChange = debounce(onBufferChange, 30)

  workspace.registerAutocmd({ event: 'DirChanged', request: true, callback: onChangeDirectory })
  workspace.registerAutocmd({ event: 'BufWinEnter', request: false, callback: debouncedBufferChange })
  workspace.registerAutocmd({ event: 'WinEnter', request: false, callback: debouncedBufferChange })

  commands.registerCommand('vim-js.cdGitRoot', cdGitRoot)
  commands.registerCommand('vim-js.cdProjectRoot', cdProjectRoot)
  commands.registerCommand('vim-js.cdCurrentPath', cdCurrentPath)

  nvim.command('command! CDG :CocCommand vim-js.cdGitRoot')
  nvim.command('command! CDR :CocCommand vim-js.cdProjectRoot')
  nvim.command('command! CDC :CocCommand vim-js.cdCurrentPath')

  onVimEnter()
}
