/* eslint-disable no-console */
/* eslint-disable @typescript-eslint/no-var-requires */
async function start(watch) {
  await require('esbuild').build({
    entryPoints: ['src/index.ts'],
    bundle: true,
    minify: false,
    watch,
    sourcemap: true,
    mainFields: ['module', 'main'],
    external: ['coc.nvim', 'typescript'],
    platform: 'node',
    target: ['es2020', 'node14'],
    outfile: 'dist/index.js',
  })
}

let watch = false
if (process.argv.length > 2 && process.argv[2] === '--watch') {
  console.log('watching...')
  watch = {
    onRebuild(error) {
      if (error) {
        console.error('watch build failed:', error)
      } else {
        console.log('watch build succeeded')
      }
    },
  }
}

start(watch).catch(e => {
  console.error(e)
})
