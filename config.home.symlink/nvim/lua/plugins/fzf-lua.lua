-- fzf-lua: Fast and fully customizable fzf for neovim
return {
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('fzf-lua').setup({
        winopts = {
          preview = {
            default = 'bat',
          },
        },
      })
    end,
  },
}
