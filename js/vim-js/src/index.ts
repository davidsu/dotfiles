//eslint-disable-next-line require-await
export async function activate() {
  require('./autocd')
  require('./goToDeclaration')
  require('./formatBufferByType')
  // require('./vimspectorHelper')
  // require('./jest-runner')
}
