-- fzf-lua: Fast and fully customizable fzf for neovim
-- Loaded only in terminal (VSCode/Cursor has Cmd+P)

local env = require('core.env')

if env.is_vscode then
  return {}
end

local function get_winopts()
  return {
    height = 1,
    width = 1,
    preview = {
      default = 'bat',
      layout = 'vertical',
      vertical = 'up:50%',
    },
  }
end

local function get_lsp_opts()
  return {
    jump_to_single_result = false, -- Always show picker, don't auto-jump
    ignore_current_line = false,
  }
end

local function grep_word_under_cursor()
  require('fzf-lua').grep_cword()
end

local function config()
  require('fzf-lua').setup({
    winopts = get_winopts(),
    lsp = get_lsp_opts(),
    keymaps = {
      previewer = false, -- Disable preview for keymaps (source path often incorrect)
    },
  })
end

return {
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    init = function()
      -- Create command aliases that will trigger lazy-load
      vim.api.nvim_create_user_command('Files', function() require('fzf-lua').files() end, {})
      vim.api.nvim_create_user_command('GFiles', function() require('fzf-lua').git_files() end, {})
      vim.api.nvim_create_user_command('Buffers', function() require('fzf-lua').buffers() end, {})
      vim.api.nvim_create_user_command('Rg', function(opts)
        if opts.args == '' then
          require('fzf-lua').grep_project()
        else
          require('fzf-lua').grep({ search = opts.args })
        end
      end, { nargs = '*' })
      vim.api.nvim_create_user_command('History', function() require('fzf-lua').oldfiles() end, {})
      vim.api.nvim_create_user_command('Commands', function() require('fzf-lua').commands() end, {})
      vim.api.nvim_create_user_command('Maps', function() require('fzf-lua').keymaps() end, {})
    end,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      -- File navigation
      { '<c-t>',     '<cmd>FzfLua git_files<cr>',       desc = 'Find git files' },
      { '<space>fa', '<cmd>FzfLua files<cr>',           desc = 'Find all files' },
      { '<space>fb', '<cmd>FzfLua buffers<cr>',         desc = 'Find buffers' },
      { '\\b',       '<cmd>FzfLua buffers<cr>',         desc = 'Find buffers' },
      { '1b',        '<cmd>FzfLua buffers<cr>',         desc = 'Find buffers' },

      -- Search
      { '<space>fw', grep_word_under_cursor,            desc = 'Grep word under cursor' },
      { '<space>bl', '<cmd>FzfLua blines<cr>',          desc = 'Search lines in buffer' },
      { '\\r',       ':Rg ',                             desc = 'Ripgrep with query' },

      -- History
      { '<space>fh', '<cmd>FzfLua command_history<cr>', desc = 'Command history' },
      { '1:',        '<cmd>FzfLua command_history<cr>', desc = 'Command history' },
      { '1;',        '<cmd>FzfLua command_history<cr>', desc = 'Command history' },
      { '1/',        '<cmd>FzfLua search_history<cr>',  desc = 'Search history' },

      -- Commands and keymaps
      { '\\c',       '<cmd>FzfLua commands<cr>',        desc = 'Commands' },
      { '\\<tab>',   '<cmd>FzfLua keymaps<cr>',         mode = 'n',                           desc = 'Search keybindings' },
      { '\\<tab>',   '<cmd>FzfLua keymaps<cr>',         mode = 'x',                           desc = 'Search keybindings' },
      { '\\<tab>',   '<cmd>FzfLua keymaps<cr>',         mode = 'o',                           desc = 'Search keybindings' },

      -- LSP and quickfix
      { '<space>fu', '<cmd>FzfLua lsp_references<cr>',  desc = 'Find usages (LSP references)' },
      { '<space>fq', '<cmd>FzfLua quickfix<cr>',        desc = 'FZF Quickfix' },
    },
    config = config,
  },
}
