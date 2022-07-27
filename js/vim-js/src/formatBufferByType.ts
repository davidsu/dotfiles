import { commands, workspace } from 'coc.nvim'
import { getApi } from './api'
import sortKeys from 'sort-keys'
import { html } from 'js-beautify'

const { nvim } = workspace

async function getLines(api, filter = (arg: string) => true) {
  const lineCount = await api.nvim_buf_line_count(0)
  const lines = await api.nvim_buf_get_lines(0, 0, lineCount, false)
  return lines.filter(filter).join('')
}

async function writeLines(lines, api) {
  const split = lines.split('\n')
  await api.nvim_buf_set_lines(0, 0, split.length + 1000, false, split)
}
async function prettyHtml(api) {
  const pretty = html(await getLines(api), {
    unformatted: ['svg'],
    indent_size: 2,
    wrap_line_length: 200,
    wrap_attributes: 'force',
    inline: [],
  })
    .replace(/(<svg.*?\/svg>)/gm, (_, g) => g.replace(/\s+/g, ' '))
    .replace(/(<\w+)([^>]*?)(data-testid="[^"]+")/g, (_, tag, rest, testid) =>
      `${tag} ${testid} ${rest}`.replace(/\s\s+/, ' ')
    )
    .replace(/\n\s+(\w)/g, ' $1')
  await writeLines(pretty, api)
}

async function bufferToObject(api) {
  const lines = await getLines(api, line => !/^\s+\/\//.test(line))
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
  jsonc: formatJson,
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
