import { commands, workspace } from 'coc.nvim'
import { existsSync } from 'fs'
import { execSync } from 'child_process'
import { getApi } from './api'
import path from 'path'
const { nvim } = workspace
let api
const getCursorPosition = () => api.nvim_win_get_cursor(0)
const str = obj => JSON.stringify(obj)

async function jumpImplementation(pos) {
  await api.nvim_call_function('CocAction', ['jumpImplementation'])
  await new Promise(r => setTimeout(r, 25))
  const newPos = await getCursorPosition()
  return str(pos) !== str(newPos)
}

async function fallbackFZF() {
  const line = await nvim.line
  const pos = await getCursorPosition()
  const lineFromCursorPosition = line.substring(pos[1])
  const isFunction = /^[\w\s]*\(/.test(lineFromCursorPosition)
  const word = await api.nvim_eval("expand('<cword>')")
  if (isFunction) {
    api.nvim_call_function('FindFunction', [
      word,
      " --ignore '*.spec.js' --ignore '*.unit.js' --ignore '*.it.js' --ignore '*.*.spec.js' --ignore '*.*.*unit.js' --ignore '*.*.*it.js'",
    ])
  } else {
    const options = [
      '--preview-window up:50%',
      "--preview '$HOME/.dotfiles/config/nvim/plugged/fzf.vim/bin/preview.rb'\\ -v\\ {}",
      "--header 'CTRL-o - open without abort :: CTRL-s - toggle sort :: CTRL-g - toggle preview window'",
      "--bind 'ctrl-g:toggle-preview,ctrl-o:execute:$DOTFILES/fzf/fhelp.sh {} > /dev/tty'",
    ].join(' ')
    const down = '100%'
    api.nvim_call_function('fzf#vim#ag', [`\\b${word}\\b`, { options, down }, 1])
  }
}

async function jumpImport() {
  try {
    let fileName
    const line = await nvim.line
    const isImport = /^\s*import\b.*from\s+['"]/.test(line)
    const isRequireOrDynamicImport = /\b(require|import)\((['"].*['"])/.test(line)
    const currentBufferPath = await api.nvim_eval("expand('%:p')")
    if (isImport) {
      fileName = line.replace(/.*['"](.*)['"].*/, '$1')
    } else if (isRequireOrDynamicImport) {
      fileName = line.replace(/.*\b(require|import)\(['"](.*)['"].*/, '$2')
    }
    if (/^\./.test(fileName)) {
      const desiredFilePath = path.join(await api.nvim_eval("expand('%:p:h')"), fileName)
      const filePath = [desiredFilePath, `${desiredFilePath}.js`, `${desiredFilePath}.ts`].find(p => existsSync(p))
      if (filePath) {
        nvim.command('edit ' + filePath)
        return true
      }
    } else if (fileName) {
      const getFilePathCMD = `node -e 'console.log(require.resolve("${fileName}", {paths: ["${currentBufferPath}"]}))'`

      const absolutePath = execSync(getFilePathCMD).toString().trim()
      if (absolutePath) {
        const word = await nvim.callFunction('expand', '<cword>')
        await nvim.command(`let @/='${word}'`)
        await nvim.command(`edit ${absolutePath}`)
        return true
      }
    }
    } catch(e) { //eslint-disable-line 
  }
}

commands.registerCommand('vim-js.goToDeclaration', async () => {
  api = await getApi()
  debugger
  const pos = await getCursorPosition()
  ;(await jumpImplementation(pos)) || (await jumpImport()) || fallbackFZF()
})
nvim.command('command! JSGoToDeclaration :CocCommand vim-js.goToDeclaration')
