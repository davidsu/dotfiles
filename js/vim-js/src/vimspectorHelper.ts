import { execSync } from 'child_process'
import { commands, workspace, BasicList, listManager } from 'coc.nvim'
import { existsSync, writeFileSync } from 'fs'
import path from 'path'
import { getProjectRoot, getGitRoot } from './utils'
const { nvim } = workspace

const vimspectorFunctions = [
  'vimspector#launch() abort',
  'vimspector#launchwithsettings( settings ) abort',
  'vimspector#reset() abort',
  'vimspector#restart() abort',
  'vimspector#clearbreakpoints() abort',
  'vimspector#togglebreakpoint( ... ) abort',
  'vimspector#SetLineBreakpoint( file_name, line_num, ... ) abort',
  'vimspector#ClearLineBreakpoint( file_name, line_num ) abort',
  'vimspector#RunToCursor() abort',
  'vimspector#AddFunctionBreakpoint( function, ... ) abort',
  'vimspector#StepOver() abort',
  'vimspector#StepInto() abort',
  'vimspector#StepOut() abort',
  'vimspector#Continue() abort',
  'vimspector#Pause() abort',
  'vimspector#PauseContinueThread() abort',
  'vimspector#SetCurrentThread() abort',
  'vimspector#Stop() abort',
  'vimspector#ExpandVariable() abort',
  'vimspector#DeleteWatch() abort',
  'vimspector#GoToFrame() abort',
  'vimspector#AddWatch( ... ) abort',
  'vimspector#AddWatchPrompt( expr ) abort',
  'vimspector#Evaluate( expr ) abort',
  'vimspector#EvaluateConsole( expr ) abort',
  'vimspector#ShowOutput( ... ) abort',
  'vimspector#ShowOutputInWindow( win_id, category ) abort',
  'vimspector#ToggleLog() abort',
  'vimspector#ListBreakpoints() abort',
  'vimspector#GetConfigurations() abort',
  'vimspector#CompleteOutput( ArgLead, CmdLine, CursorPos ) abort',
  'vimspector#CompleteExpr( ArgLead, CmdLine, CursorPos ) abort',
  'vimspector#CompleteFuncSync( prompt, find_start, query ) abort',
  'vimspector#OmniFuncWatch( find_start, query ) abort',
  'vimspector#OmniFuncConsole( find_start, query ) abort',
  'vimspector#Install( bang, ... ) abort',
  'vimspector#CompleteInstall( ArgLead, CmdLine, CursorPos ) abort',
  'vimspector#Update( bang, ... ) abort',
  'vimspector#AbortInstall() abort',
  'vimspector#OnBufferCreated( file_name ) abort',
]
class List extends BasicList {
  name = 'vimspector'
  action = 'open'
  public description = 'whaat'
  constructor() {
    super(nvim)
    //eslint-disable-next-line
    this.addAction('open', async function (item) {
      nvim.call(item.label.replace(/\(.*/, ''))
    })
  }
  //eslint-disable-next-line
  async loadItems() {
    return vimspectorFunctions.map(func => ({
      label: func,
      data: {
        name: func,
      },
    }))
  }
}

listManager.registerList(new List())
const mapsConfig = {
  w: ['watches', 'goToWindow'],
  c: ['code', 'goToWindow'],
  s: ['stack_trace', 'goToWindow'],
  v: ['variables', 'goToWindow'],
  t: ['output', 'goToWindow'], // terminal(in my understanding of what I'd expect terminal to be
  i: ['StepInto', 'func'],
  ou: ['StepOut', 'func'],
  oo: ['StepOver', 'func'],
  p: ['Pause', 'func'],
  r: ['Restart', 'func'],
  n: ['Continue', 'func'], // next
  q: ['CocCommand vim-js.vimspector.stop', 'command'], // quit
  '<space>br': ['ToggleBreakpoint', 'func'],
}

const mapsCaller = {
  keymap: (name, key) => nvim.command(`nmap ${key} ${name}`),
  command: (name, key) => nvim.command(`nmap ${key} :${name}<cr>`),
  func: (name, key) => nvim.command(`nmap ${key} :call vimspector#${name}()<cr>`),
  goToWindow: async (name, key) => {
    const goToWindow = `win_gotoid(g:vimspector_session_windows.${name})`
    nvim.command(`nmap ${key} :call ${goToWindow}<cr>`)
    await nvim.eval(goToWindow)
    await nvim.command(`nmap <buffer> ${key} :call Zoom()<cr>`)
  },
}

const maps = Object.entries(mapsConfig).map(([key, [val, cmd]]) => {
  const vimkey = /\</.test(key)
    ? key
    : key
        .split('')
        .map(k => `<C-${k}>`)
        .join('')
  const setupFn = () => mapsCaller[cmd](val, vimkey)
  const saveMapEval = `['${vimkey}', maparg('${vimkey}', 'n')]`
  return {
    vimkey,
    setupFn,
    saveMapEval,
    restore: '',
  }
})

function tearDown() {
  nvim.callFunction('vimspector#Reset')
  nvim.setOption('eventignore', '') //ultisnip error
  for (const map of maps) {
    if (map.restore) {
      nvim.command(`nmap ${map.vimkey} ${map.restore}`)
    } else {
      nvim.command(`unmap ${map.vimkey}`)
    }
  }
}

async function setupMaps() {
  debugger
  for (const map of maps) {
    map.restore = (await nvim.eval(`maparg('${map.vimkey}', 'n')`)) as string
    await map.setupFn()
  }
}

async function runJest() {
  // nvim.command('augroup! UltiSnips_AutoTrigger')
  nvim.setOption('eventignore', 'TextChangedI') //ultisnip error
  const hasdebugger = await nvim.call('exists', '*VimspectorEval')
  if (!hasdebugger) {
    // call plug#begin('~/.config/nvim/plugged')
    // Plug 'puremourning/vimspector'
    // call plug#end()
    await nvim.call('SetupDebugger')
  }

  const currentFile = await nvim.call('expand', '%:p')
  const projectRoot = getProjectRoot(currentFile)
  const gitRoot = getGitRoot(currentFile)
  const projectJest = path.join(projectRoot, 'node_modules/.bin/jest')
  const jestExecutable = existsSync(projectJest) ? projectJest : path.join(gitRoot, 'node_modules/.bin/jest')
  const vimspectorConfig = {
    configurations: {
      run: {
        adapter: 'vscode-node',
        configuration: {
          request: 'launch',
          protocol: 'auto',
          stopOnEntry: false,
          console: 'integratedTerminal',
          sourceMap: false,
          breakpoints: {
            exception: {
              caught: 'N',
              uncaught: 'Y',
            },
          },
          args: [currentFile],
          runtimeVersion: '14.15.3',
          program: jestExecutable,
          cwd: projectRoot,
        },
      },
    },
  }
  writeFileSync(path.join(projectRoot, '.vimspector.json'), JSON.stringify(vimspectorConfig))
  nvim.call('vimspector#Launch')
}

nvim.command('command! RunJest CocCommand vim-js.runJest')
commands.registerCommand('vim-js.runJest', runJest)
commands.registerCommand('vim-js.vimspector.start', setupMaps)
commands.registerCommand('vim-js.vimspector.stop', tearDown)
