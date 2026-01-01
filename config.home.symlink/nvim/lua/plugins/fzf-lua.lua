-- fzf-lua: Fast and fully customizable fzf for neovim
return {
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<space>fu', '<cmd>FzfLua lsp_references<cr>', desc = 'Find usages (LSP references)' },
      { '<space>fq', '<cmd>FzfLua quickfix<cr>', desc = 'FZF Quickfix' },
    },
    config = function()
      require('fzf-lua').setup({
        winopts = {
          height = 0.95,
          width = 0.95,
          preview = {
            default = 'bat',
            layout = 'vertical',
            vertical = 'up:50%',
          },
        },
        lsp = {
          -- Show context around references (like your old setup)
          jump1 = false,  -- Don't auto-jump if only one result, always show picker
          ignore_current_line = false,
        },
      })
    end,
  },
}
