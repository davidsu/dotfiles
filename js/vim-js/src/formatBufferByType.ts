import { commands, workspace } from 'coc.nvim'
import { getApi } from './api'
import sortKeys from 'sort-keys'
//using prettier standalone + parserHtml to get ~1M bundle instead of 13M
import { format } from 'prettier/standalone'
import parserHtml from 'prettier/parser-html'

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
  const pretty = format(await getLines(api), { parser: 'html', printWidth: 240, plugins: [parserHtml] })
  await writeLines(pretty, api)
}

async function bufferToObject(api) {
  const lines = await getLines(api)
  try {
    return JSON.parse(lines)
  } catch (e) {
    //assume we have javascript object in buffer
    //use (0, eval) to satisfy esbuild.js
    return JSON.parse((0, eval)(`JSON.stringify(${lines})`))
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
  debugger
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
