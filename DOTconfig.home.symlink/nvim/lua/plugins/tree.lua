-- File Explorer

local function find_file_in_tree()
  local root = vim.fn.FugitiveWorkTree()
  if root ~= '' then vim.fn.chdir(root) end
  vim.cmd('NvimTreeFindFile')
end

local keys = {
  { '1n', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle file tree' },
  { '<space>nf', find_file_in_tree, desc = 'Find file in tree' },
}

local function on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function map_opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)

  vim.keymap.set('n', 'g?', function()
    local keymaps = api.config.mappings.get_keymap()
    local entries = {}
    local lhs_by_line = {}
    for _, km in ipairs(keymaps) do
      local desc = (km.desc or ''):gsub('^nvim%-tree: ', '')
      if desc ~= '' then
        local entry = string.format('%-14s %s', km.lhs, desc)
        table.insert(entries, entry)
        lhs_by_line[entry] = km.lhs
      end
    end
    table.sort(entries)
    local win = vim.api.nvim_get_current_win()
    require('fzf-lua').fzf_exec(entries, {
      prompt = 'NvimTree Keymaps> ',
      winopts = { height = 0.6, width = 0.5 },
      actions = {
        ['default'] = function(selected)
          if not selected or not selected[1] then return end
          local lhs = lhs_by_line[selected[1]]
          if not lhs or not win or not vim.api.nvim_win_is_valid(win) then return end
          vim.api.nvim_set_current_win(win)
          local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
          vim.api.nvim_feedkeys(keys, 'm', false)
        end,
      },
    })
  end, map_opts('Help'))
end

local opts = {
  on_attach = on_attach,
  disable_netrw = true,
  hijack_netrw = true,
  view = { width = 40, side = 'left' },
  renderer = {
    group_empty = true,
    highlight_git = true,
    icons = { show = { git = true, folder = true, file = true, folder_arrow = true } },
  },
  filters = { dotfiles = false, custom = {} },
  git = { enable = true, ignore = false },
  actions = { open_file = { quit_on_open = false, resize_window = true } },
}

return {
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = keys,
    opts = opts,
  },
}


