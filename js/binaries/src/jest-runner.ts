/* eslint-disable no-console */
import { execSync, spawn } from 'child_process'
import { readFileSync } from 'fs'
import { openChromeOnDebuggerUrl } from './debugInChrome'
function getJestCommand(projectRoot, isInspect) {
  const jestBin = execSync('yarn bin jest', { cwd: projectRoot }).toString().trim()
  const runner = isInspect ? 'ndb' : 'node'
  return `${runner} ${jestBin}`
}

function getReactTestCommand(isInspect, testCommand) {
  const postFix = isInspect ? '--inspect-brk test' : 'test'
  return `yarn ${testCommand} ${postFix}`
}

function getTestCommand(projectRoot, isInspect) {
  const {
    scripts: { test },
  } = JSON.parse(readFileSync(`${projectRoot}/package.json`).toString())
  const testCommand = test.replace(/.*\b(react-app-rewired|react-scripts|jest)\b.*/, '$1')
  const testCommandPrefix =
    testCommand === 'jest' ? getJestCommand(projectRoot, isInspect) : getReactTestCommand(isInspect, testCommand)
  const testCommandPostfix = isInspect ? '--testTimeout=0' : ''
  return `${testCommandPrefix} ${testCommandPostfix}`
}

const isInspectArg = arg => /--inspect/.test(arg)
export function runjest(args, projectRoot) {
  const isInspect = !!args.find(isInspectArg)
  const [runner, ...spawnArgs] = getTestCommand(projectRoot, isInspect).split(' ')
  const otherArgs = args.filter(a => !isInspectArg(a))
  const allSpawnArgs = [...spawnArgs, ...otherArgs].filter(a => !!a)
  console.log(JSON.stringify({ cwd: projectRoot, env: { CI: '1', FORCE_COLOR: '1' } }, null, 2))
  console.log(`${runner} ${allSpawnArgs.join(' ')}`)
  const jest = spawn(runner, allSpawnArgs, { cwd: projectRoot, env: { CI: '1', FORCE_COLOR: '1', ...process.env } })

  function ondata(e, d) {
    const data = d.toString()
    console.log(data)

    if (/Debugger listening on/.test(data)) {
      //source https://github.com/ChromeDevTools/debugger-protocol-viewer/blob/33bdf34ea60c35c483261f398265a821f2e2c4f3/pages/index.md
      openChromeOnDebuggerUrl(Number(args.find(isInspectArg).split('=')[1]) || 9229)
    }

    if (/Waiting for the debugger to disconnect/.test(data)) {
      jest.kill(0)
    }
  }

  jest.stdout.on('data', data => ondata('out', data))
  jest.stderr.on('data', data => ondata('err', data))
  jest.on('close', () => {
    console.log('finished!!')
  })
}
