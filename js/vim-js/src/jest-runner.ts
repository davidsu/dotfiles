import { commands } from 'coc.nvim'
import { getApi } from './api'
import { getProjectRoot } from 'common/src/utils'

const runjest = async isInspect => {
  const api = await getApi()
  let testPath = await api.nvim_eval("expand('%:p')")
  const projectRoot = getProjectRoot(testPath)
  testPath = testPath.replace(projectRoot, '').replace(/^\/?/, '')
  const command = `cd ${projectRoot}; runjest ${isInspect} --no-coverage ${testPath}`
  api.nvim_call_function('utils#run_shell_command', [command, 0])
}

commands.registerCommand('vim-js.runjest', runjest)
