import fetch from 'node-fetch'
import chalk from 'chalk'
import { spawn, execSync } from 'child_process'
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs'
const gitProj = execSync('git rev-parse --show-toplevel', { encoding: 'utf8' }).trim()
const CACHE_DIR = `${gitProj}/.git/davidsu`
const PROJID = 'projid.txt'
const JOBS = 'jobs.json'
const TABLE = 'table.txt'
const GIT_REMOTE = execSync('git config --get remote.origin.url', { encoding: 'utf8' }).trim()
const NUM_PAGES_TO_FETCH = 80

const gitlabToken = process.env.GITLAB_TOKEN

const apiGet = url =>
  fetch(`https://gitlab.com/api/v4/${url}`, {
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${gitlabToken}`,
    },
  }).then(response => response.json())

if (!existsSync(CACHE_DIR)) {
  mkdirSync(CACHE_DIR)
}

function runWithCache(file, cmd) {
  const FILE = `${CACHE_DIR}/${file}`
  const promise = cmd().then(result => {
    writeFileSync(FILE, result)
    return result
  })

  if (existsSync(FILE)) {
    return Promise.resolve(readFileSync(FILE, { encoding: 'utf8' }))
  }
  return promise
}

function getProjectId() {
  return runWithCache(PROJID, () =>
    apiGet(`projects?membership=true&search=${gitProj.replace(/.*\/(.+)/, '$1')}`).then(resultArr => {
      const result = resultArr.find(({ ssh_url_to_repo }) => ssh_url_to_repo === GIT_REMOTE)
      const id = String(result.id)
      debugger
      return id
    })
  )
}

function getJob(projectId, pageNumber) {
  return runWithCache(`${JOBS}_${pageNumber}`, () =>
    apiGet(`projects/${projectId}/jobs?per_page=100&page=${pageNumber}`).then(res => JSON.stringify(res))
  )
}
function getJobs(projectId) {
  return runWithCache(JOBS, async () => {
    const promises = await Promise.all(Array.from({ length: NUM_PAGES_TO_FETCH }, (_, i) => getJob(projectId, i + 1)))
    const flat = promises.map(p => JSON.parse(p)).flat()
    return JSON.stringify(flat)
  })
}

function colorStatus(status) {
  if (/success/.test(status)) {
    return chalk.green(status)
  }
  if (/failed/.test(status)) {
    return chalk.red(status)
  }
  if (/(running|pending)/.test(status)) {
    return chalk.blue(status)
  }
  return status
}
// eslint-disable-next-line require-await
async function formatForFzf(jobs) {
  return runWithCache(TABLE, () => {
    return Promise.resolve(
      JSON.parse(jobs)
        .map(job => {
          // return [job.status, job.stage, job.name, job.ref, job.started_at].join('  ')
          return [
            job.name.padEnd(50, ' '),
            colorStatus(job.status.padEnd(10, ' ')),
            job.stage.padEnd(10, ' '),
            (job.user?.username || '').padEnd(15, ' '),
            job.ref.padEnd(22, ' '),
            (job.started_at || 'NOT STARTED').padEnd(30, ' '),
            job.id,
          ].join('  ')
        })
        .join('\n')
    )
  })
}

async function runFzf() {
  try {
    const result = execSync(`cat ${CACHE_DIR}/${TABLE} | fzf --ansi > /tmp/selected`, {
      stdio: [0, 1, 2],
      encoding: 'utf8',
    })
    const id = readFileSync('/tmp/selected', { encoding: 'utf8' })
      .trim()
      .replace(/.*\s(\d+)/, '$1')
    const jobs = await getJobs(await getProjectId())
    const { web_url } = jobs.find(job => job.id == id)
    execSync(`open '${web_url}'`)
    console.log({ result, id })
  } catch (e) {}
}

const promise = getProjectId().then(getJobs).then(formatForFzf)

if (!process.argv.find(arg => arg == '--reload')) {
  spawn('node', [__filename, '--reload'], { detached: true })
  promise
    .then(runFzf)
    .catch(e => console.log('e', e))
    .then(() => process.exit(0))
} // local project_id=$(glab api "projects?membership=true&search=$(basename "$(git rev-parse --show-toplevel)")" | jq -r '.[0].id')
