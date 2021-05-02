//eslint-disable-next-line require-await
export async function activate() {
  require('./autocd')
  require('./goToDeclaration')
  require('./prettyHtml')
  // require('./vimspectorHelper')
  // require('./jest-runner')
}
