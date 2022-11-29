/* eslint-disable no-console */
import { execSync, spawn, exec } from 'child_process'
import { readFileSync } from 'fs'
function getJestCommand(projectRoot, isInspect) {
  const jestBin = execSync('yarn bin jest', { cwd: projectRoot }).toString().trim()
  const runner = isInspect ? 'node --inspect-brk' : 'node'
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
  const testCommand = (test || 'jest').replace(/.*\b(react-app-rewired|react-scripts|jest)\b.*/, '$1')
  const testCommandPrefix =
    testCommand === 'jest' ? getJestCommand(projectRoot, isInspect) : getReactTestCommand(isInspect, testCommand)
  const testCommandPostfix = isInspect ? `--testTimeout=${2 ** 31 - 1}` : ''
  return `${testCommandPrefix} ${testCommandPostfix}`
}

const isInspectArg = arg => /--inspect/.test(arg)
const getPort = inspect => Number(inspect.split('=')[1]) || 9229
function killPortHolderIfExists(inspect) {
  if (inspect) {
    // automatic kill application holding my debugging port
    const port = getPort(inspect)
    try {
      console.log(execSync(`kill $(lsof -i tcp:${port} -t)`).toString())
    } catch (e) {}
  }
}
export function runjest(args, projectRoot) {
  const inspect = args.find(isInspectArg)
  const [runner, ...spawnArgs] = getTestCommand(projectRoot, !!inspect).split(' ')
  const otherArgs = args.filter(a => !isInspectArg(a))
  const allSpawnArgs = [...spawnArgs, ...otherArgs].filter(a => !!a)
  console.log(JSON.stringify({ cwd: projectRoot, env: { CI: '1', FORCE_COLOR: '1' } }, null, 2))
  console.log(`${runner} ${allSpawnArgs.join(' ')}`)
  killPortHolderIfExists(inspect)
  const jest = spawn(runner, allSpawnArgs, { cwd: projectRoot, env: { CI: '1', FORCE_COLOR: '1', ...process.env } })

  function ondata(e, d) {
    const data = d.toString()
    console.log(data)

    if (/Debugger listening on/.test(data)) {
      exec(`source ${process.env.DOTFILES}/bin/inspect ${getPort(inspect)}`)
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
