import { commands, workspace } from 'coc.nvim'
import { existsSync } from 'fs'
import { execSync } from 'child_process'
import { getApi } from './api'
import path from 'path'
const { nvim } = workspace
let api
const getCursorPosition = () => api.nvim_win_get_cursor(0)
const str = obj => JSON.stringify(obj)

async function jumpWithCoc(pos, method) {
  await api.nvim_call_function('CocAction', [method])
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
      "--preview '$HOME/.dotfiles/bin/preview.rb'\\ -v\\ {}",
      "--header 'CTRL-o - open without abort :: CTRL-s - toggle sort :: CTRL-g - toggle preview window'",
      "--bind 'ctrl-g:toggle-preview,ctrl-o:execute:$DOTFILES/fzf/fhelp.sh {} > /dev/tty'",
      "--query '!build/ !coverage/'",
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

async function isTSTypeFile() {
  const filePath = await api.nvim_eval("expand('%:p')")
  return /\.d\.ts$/.test(filePath)
}

async function definitionFileHandler() {
  await rewind('<c-o>')
  fallbackFZF()
}

const isCocList = async () => (await api.nvim_buf_get_option(0, 'filetype')) === 'list'

async function cocListHandler() {
  const lineCount = await api.nvim_buf_line_count(0)
  const lines = await api.nvim_buf_get_lines(0, 0, lineCount, false)
  const nonTypeDefinition = lines.map((line, i) => [line, i]).filter(line => !/\.d\.ts\b/.test(line))
  if (nonTypeDefinition.length === 0) {
    await rewind('<esc>')
    fallbackFZF()
  } else if (nonTypeDefinition.length === 1) {
    await rewind(`%{nonTypeDefinition[0][1]}G<cr>`)
  }
}

async function rewind(rewindKeys, wait = 50) {
  const escapedRewindKeys = await api.nvim_replace_termcodes(rewindKeys, true, false, true)
  await api.nvim_feedkeys(escapedRewindKeys, 'n', true)
  await new Promise(r => setTimeout(r, wait))
}

async function goToDeclaration() {
  api = await getApi()
  const pos = await getCursorPosition()
  const jumpFail = !(
    (await jumpWithCoc(pos, 'jumpImplementation')) ||
    (await jumpWithCoc(pos, 'jumpDefinition')) ||
    (await jumpImport())
  )

  if (await isTSTypeFile()) {
    definitionFileHandler()
  } else if (await isCocList()) {
    cocListHandler()
  } else if (jumpFail && str(pos) === str(await getCursorPosition())) {
    fallbackFZF()
  }
}

commands.registerCommand('vim-js.goToDeclaration', () => {
  goToDeclaration()
})

nvim.command('command! JSGoToDeclaration :CocCommand vim-js.goToDeclaration')
