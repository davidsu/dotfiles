-- Git Integration Plugins
-- Loaded only in terminal (VSCode/Cursor has built-in git)

local env = require('core.env')

if env.is_vscode then
  return {}
end

local function get_signs()
  return {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  }
end

local function next_hunk()
  if vim.wo.diff then return ']g' end
  vim.schedule(function() package.loaded.gitsigns.next_hunk() end)
  return '<Ignore>'
end

local function prev_hunk()
  if vim.wo.diff then return '[g' end
  vim.schedule(function() package.loaded.gitsigns.prev_hunk() end)
  return '<Ignore>'
end

local function buffer_keymap(bufnr, mode, lhs, rhs, opts)
  opts = opts or {}
  opts.buffer = bufnr
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function on_attach(bufnr)
  local gs = package.loaded.gitsigns

  buffer_keymap(bufnr, 'n', ']g', next_hunk, { expr = true, desc = 'Next git hunk' })
  buffer_keymap(bufnr, 'n', '[g', prev_hunk, { expr = true, desc = 'Previous git hunk' })
  buffer_keymap(bufnr, 'n', '<space>hs', gs.stage_hunk, { desc = 'Stage hunk' })
  buffer_keymap(bufnr, 'n', '<space>hr', gs.reset_hunk, { desc = 'Reset hunk' })
  buffer_keymap(bufnr, 'n', '<space>hu', gs.undo_stage_hunk, { desc = 'Undo stage hunk' })
  buffer_keymap(bufnr, 'n', '<space>hp', gs.preview_hunk, { desc = 'Preview hunk' })
end

local function gitsigns_config()
  require('gitsigns').setup({
    signs = get_signs(),
    signs_staged = get_signs(),
    signcolumn = false, -- disable gitsigns in sign column
    on_attach = on_attach,
  })
end

local fugitive = {
  'tpope/vim-fugitive',
  cmd = { 'Git', 'Gread', 'Gwrite', 'Gdiffsplit', 'Gvdiffsplit' },
  keys = {
    { '<space>gs', '<cmd>Git<cr>', desc = 'Git status' },
    { 'gs', '<cmd>Git<cr>', desc = 'Git status' },
    { '<space>gd', '<cmd>Gdiffsplit<cr>', desc = 'Git diff' },
    { 'gb', '<cmd>Git blame<cr>', desc = 'Git blame' },
  },
}

local rhubarb = {
  'tpope/vim-rhubarb',
  dependencies = { 'tpope/vim-fugitive' },
}

local gitsigns = {
  'lewis6991/gitsigns.nvim',
  event = 'BufReadPre',
  config = gitsigns_config,
}

return {
  fugitive,
  rhubarb,
  gitsigns,
}


