//eslint-disable-next-line require-await
export async function activate() {
  //todo:
  //duplicate code utils and autocd
  //duplicate code .dotfiles/bin/debugger and jest-runner
  require('./autocd')
  require('./goToDeclaration')
  require('./formatBufferByType')
  // require('./vimspectorHelper')
  require('./jest-runner')
}
