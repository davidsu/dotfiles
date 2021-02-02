local isModuleAvailable = require 'utils'.isModuleAvailable
if not isModuleAvailable('lspconfig/configs') or not isModuleAvailable('lspconfig/util') then
  return
end
local M = {}
M.jumpDeclaration = function()
  local initial_position = vim.api.nvim_win_get_position('.')
  vim.lsp.buf.implementation()
  local position = vim.api.nvim_win_get_position('.')
  if initial_position[1] ~= position[1] or initial_position[2] ~= position[2] then
    return
  end
  vim.lsp.buf.definition()
  if initial_position[1] ~= position[1] or initial_position[2] ~= position[2] then
    return
  end
  vim.cmd('JSGoToDeclaration')

end
function customAttach() 
    buf_set_keymap('n', 'gd', '<Cmd>lua require("lsp_configuration").jumpDeclaration()<CR>', opts)
end
require('lspconfig').tsserver.setup( {
  cmd = {"typescript-language-server", "--stdio"},
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx"
  },
  diagnostics = { enable = false },
  on_attach = function() print('tsserver attached') end
})
vim.lsp.callbacks["textDocument/publishDiagnostics"] = function() end

-- vim:et ts=2 sw=2
