-- fzf-lua: Fast and fully customizable fzf for neovim

local function get_winopts()
  return {
    height = 1,
    width = 1,
    preview = {
      default = 'bat',
      layout = 'vertical',
      vertical = 'up:50%',
      wrap = true,
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

local function grep_with_lookaround(pattern, title)
  local lookaround_rg_opts =
    '--pcre2 --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e'
  require('fzf-lua').grep({
    search = pattern,
    no_esc = true,
    prompt = '> ',
    winopts = { title = ' ' .. title .. ' ' },
    rg_opts = lookaround_rg_opts,
  })
end

local function find_function()
  local name = vim.fn.expand('<cword>')
  local function_keyword = '(?<=function\\s)' .. name .. '(?=\\s*\\()'
  local object_or_requirejs_method = '\\b' .. name .. '\\s*:'
  local shorthand_or_class_method = '^[\\t ]*' .. name .. '\\([^)]*\\)\\s*\\{\\s*$'
  local prototype_method = '(?<=prototype\\.)' .. name .. '(?=\\s*=\\s*function)'
  local assigned_function_or_arrow =
    '(var|let|const|this\\.)\\s*' .. name .. '(?=\\s*=\\s*(function|(\\([^)]*\\)|\\w+)\\s*=>)\\s*)'
  local ts_class_method = '(public|private)\\s+(async\\s+)?' .. name .. '\\('
  local indented_async_method = '^[\\t ]+async\\s+' .. name .. '\\('
  local definition_patterns = {
    function_keyword,
    object_or_requirejs_method,
    shorthand_or_class_method,
    prototype_method,
    assigned_function_or_arrow,
    ts_class_method,
    indented_async_method,
  }
  grep_with_lookaround(table.concat(definition_patterns, '|'), 'Find function')
end

local function find_usage()
  local name = vim.fn.expand('<cword>')
  local called_but_not_defined = '(?<!function\\s)\\b' .. name .. '(?=\\()'
  grep_with_lookaround(called_but_not_defined, 'Find usage')
end

local function file_edit_and_qf(selected, opts)
  local actions = require('fzf-lua.actions')
  if #selected > 1 then
    actions.file_edit({ selected[1] }, opts)
    actions.file_sel_to_qf(selected, opts)
    vim.cmd('wincmd p')
  else
    actions.file_edit(selected, opts)
  end
end

local function config()
  local terminal_parity_bindings = {
    ['ctrl-l'] = 'select-all',
    ['tab'] = 'toggle+down',
    ['shift-tab'] = 'toggle+up',
    ['ctrl-/'] = 'toggle-preview',
    ['ctrl-s'] = 'toggle-sort',
  }
  local grep_keybind_hints = '<ctrl-l> select-all  ·  <tab> toggle  ·  <ctrl-g> regex/fuzzy  ·  <ctrl-/> preview'
  local normal_prompt_hl = 'FzfLuaFzfPrompt'
  local split_horizontally = require('fzf-lua.actions').file_split

  require('fzf-lua').setup({
    winopts = get_winopts(),
    lsp = get_lsp_opts(),
    fzf_opts = { ['--multi'] = '' },
    hls = { live_prompt = normal_prompt_hl },
    grep = { header = grep_keybind_hints },
    keymap = { fzf = terminal_parity_bindings },
    actions = {
      files = {
        ['enter'] = file_edit_and_qf,
        ['ctrl-s'] = false,
        ['ctrl-x'] = split_horizontally,
      },
    },
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
          require('fzf-lua').live_grep()
        else
          require('fzf-lua').grep({ search = opts.args, no_esc = true })
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

      -- Search
      { '<space>fw', grep_word_under_cursor,            desc = 'Grep word under cursor' },
      { '<space>ff', find_function,                     desc = 'Find function definition (grep)' },
      { '<space>bl', '<cmd>FzfLua blines<cr>',          desc = 'Search lines in buffer' },
      { '\\r',       ':Rg ',                            desc = 'Ripgrep with query' },

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
      { '<space>fu', find_usage,                        desc = 'Find usages (grep call sites)' },
      { '<space>fq', '<cmd>FzfLua quickfix<cr>',        desc = 'FZF Quickfix' },
    },
    config = config,
  },
}
