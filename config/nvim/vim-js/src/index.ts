//eslint-disable-next-line require-await
export async function activate() {
  require('./autocd')
  require('./goToDeclaration')
  // require('./vimspectorHelper')
  require('./mrujs')
  // require('./jest-runner')
}
