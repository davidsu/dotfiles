import { commands, CompleteResult, ExtensionContext, listManager, sources, workspace } from 'coc.nvim'

export async function activate(context: ExtensionContext): Promise<void> {
  import('./autocd')
  import('./goToDeclaration')
}
