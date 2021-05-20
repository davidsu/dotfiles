import { commands, workspace } from 'coc.nvim'
import { getApi } from './api'
import { format } from 'prettier'
import sortKeys from 'sort-keys'

const { nvim } = workspace

async function getLines(api) {
  const lineCount = await api.nvim_buf_line_count(0)
  const lines = await api.nvim_buf_get_lines(0, 0, lineCount, false)
  return lines.join('')
}

async function writeLines(lines, api) {
  const split = lines.split('\n')
  await api.nvim_buf_set_lines(0, 0, split.length + 1000, false, split)
}
async function prettyHtml(api) {
  const pretty = format(await getLines(api), { parser: 'html', printWidth: 240 })
  await writeLines(pretty, api)
}

async function bufferToObject(api) {
  const lines = await getLines(api)
  try {
    return JSON.parse(lines)
  } catch (e) {
    //assume we have javascript object in buffer
    return JSON.parse(eval(`JSON.stringify(${lines})`))
  }
}
async function formatJson(api) {
  const js = await bufferToObject(api)
  const sorted = sortKeys(js, { deep: true })
  const pretty = JSON.stringify(sorted, null, 2)
  await writeLines(pretty, api)
}

const formaters = {
  html: prettyHtml,
  json: formatJson,
}
async function formatBuffer() {
  const api = await getApi()
  const ft = await api.nvim_buf_get_option(0, 'filetype')
  if (ft in formaters) {
    await formaters[ft](api)
  }
}
commands.registerCommand('vim-js.formatBufferByType', formatBuffer)
nvim.command('command! PrettyHtml :CocCommand vim-js.formatBufferByType')
nvim.command('command! PrettyJson :CocCommand vim-js.formatBufferByType')
nvim.command('command! FormatFileByType :CocCommand vim-js.formatBufferByType')
