import { commands, workspace } from 'coc.nvim'
import { html } from 'js-beautify'
import { getApi } from './api'
const { nvim } = workspace

async function prettyHtml() {
  const api = await getApi()
  const htmlStr = await api.nvim_eval('join(getline(0, 100000))')
  const pretty = html(htmlStr, { wrap_attributes: 'force', inline: [] })
  await api.nvim_command('%delete _')
  await api.nvim_call_function('append', [1, pretty.split('\n')])
}
commands.registerCommand('vim-js.prettyHtml', prettyHtml)
nvim.command('command! PrettyHtml :CocCommand vim-js.prettyHtml')
