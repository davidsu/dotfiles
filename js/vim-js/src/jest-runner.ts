import { commands } from 'coc.nvim'
import { getApi } from './api'
import { getProjectRoot } from 'common/src/utils'
import { openChromeOnDebuggerUrl } from 'binaries/src/debugInChrome'

const runjest = async isInspect => {
  const api = await getApi()
  let testPath = await api.nvim_eval("expand('%:p')")
  const projectRoot = getProjectRoot(testPath)
  testPath = testPath.replace(projectRoot, '').replace(/^\/?/, '')
  const command = `cd ${projectRoot}; runjest ${isInspect} --no-coverage ${testPath}`

  await api.nvim_command('pedit')
  await api.nvim_command('wincmd P')
  await api.nvim_command('wincmd J')
  api.nvim_command(`terminal ${command}`)
  await api.nvim_command('setlocal bufhidden=wipe noswapfile nobuflisted nomodified')
  await api.nvim_command('nnoremap <buffer>q :bwipeout!<cr>')
  await api.nvim_command('tnoremap <buffer>q :bwipeout!<cr>')
  await api.nvim_command('wincmd p')
  openChromeOnDebuggerUrl()
}

commands.registerCommand('vim-js.runjest', runjest)
