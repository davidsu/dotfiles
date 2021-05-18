import { commands } from 'coc.nvim'
import { getApi } from './api'
import { getProjectRoot } from 'common/src/utils'

const runjest = async (...args) => {
  const BANG = args.indexOf('BANG') === -1 ? 0 : 1
  args = args.filter(a => !/BANG/.test(a))
  const api = await getApi()
  let testPath = await api.nvim_eval("expand('%:p')")
  const projectRoot = getProjectRoot(testPath)
  testPath = testPath.replace(projectRoot, '').replace(/^\/?/, '')
  const command = `cd ${projectRoot}; runjest ${args.join(' ')} --no-coverage ${testPath}`
  api.nvim_call_function('utils#run_shell_command', [command, BANG])
}

commands.registerCommand('vim-js.runjest', runjest)
