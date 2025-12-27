-- File Explorer
-- Loaded only in terminal (VSCode/Cursor has built-in explorer)

local env = require('core.env')

if env.is_vscode then
  return {}
end

return {
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '1n', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle file tree' },
      { '<space>nf', '<cmd>NvimTreeFindFile<cr>', desc = 'Find file in tree' },
    },
    config = function()
      require('nvim-tree').setup({
        disable_netrw = true,
        hijack_netrw = true,
        view = {
          width = 40,
          side = 'left',
        },
        renderer = {
          group_empty = true,
          highlight_git = true,
          icons = {
            show = {
              git = true,
              folder = true,
              file = true,
              folder_arrow = true,
            },
          },
        },
        filters = {
          dotfiles = false,
          custom = { '.git', 'node_modules', '.cache' },
        },
        git = {
          enable = true,
          ignore = false,
        },
        actions = {
          open_file = {
            quit_on_open = false,
            resize_window = true,
          },
        },
      })
    end,
  },
}


