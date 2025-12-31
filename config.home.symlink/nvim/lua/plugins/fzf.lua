-- FZF Fuzzy Finder
-- Loaded only in terminal (VSCode/Cursor has Cmd+P)

local env = require('core.env')

if env.is_vscode then
  return {}
end

return {
  -- FZF binary
  {
    'junegunn/fzf',
    build = './install --bin',
  },

  -- FZF vim integration
  {
    'junegunn/fzf.vim',
    dependencies = { 'junegunn/fzf' },
    cmd = { 'Files', 'GFiles', 'Buffers', 'Rg', 'History', 'Commands', 'Maps' },  -- Load on these commands
    keys = {
      { '<c-t>', '<cmd>GFiles<cr>', desc = 'Find git files' },
      { '<space>fa', '<cmd>Files<cr>', desc = 'Find all files' },
      { '<space>fw', '<cmd>Rg<cr>', desc = 'Grep word' },
      { '<space>fb', '<cmd>Buffers<cr>', desc = 'Find buffers' },
      { '\\b', '<cmd>Buffers<cr>', desc = 'Find buffers' },
      { '1b', '<cmd>Buffers<cr>', desc = 'Find buffers' },
      { '<space>fh', '<cmd>History:<cr>', desc = 'Command history' },
      { '1:', '<cmd>History:<cr>', desc = 'Command history' },
      { '1;', '<cmd>History:<cr>', desc = 'Command history' },
      { '1/', '<cmd>History/<cr>', desc = 'Search history' },
      { '\\c', '<cmd>Commands<cr>', desc = 'Commands' },
      { '\\a', ':Rg ', desc = 'Ripgrep search (from dotfilesold)' },
      { '\\<tab>', '<cmd>Maps<cr>', mode = 'n', desc = 'Search keybindings' },
      { '\\<tab>', '<cmd>Maps<cr>', mode = 'x', desc = 'Search keybindings' },
      { '\\<tab>', '<cmd>Maps<cr>', mode = 'o', desc = 'Search keybindings' },
    },
    config = function()
      -- Fullscreen layout (not floating window)
      vim.g.fzf_layout = { down = '100%' }

      -- Rg command with preview (matching dotfilesold behavior)
      -- Preview on top with syntax highlighting via bat
      vim.cmd([[
        command! -bang -nargs=* Rg
          \ call fzf#vim#grep(
          \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>),
          \   1,
          \   fzf#vim#with_preview('up:50%', 'ctrl-/'),
          \   <bang>0)
      ]])
      
      -- Customize colors to match Neovim theme
      vim.g.fzf_colors = {
        fg = { 'fg', 'Normal' },
        bg = { 'bg', 'Normal' },
        hl = { 'fg', 'Comment' },
        ['fg+'] = { 'fg', 'CursorLine', 'CursorColumn', 'Normal' },
        ['bg+'] = { 'bg', 'CursorLine', 'CursorColumn' },
        ['hl+'] = { 'fg', 'Statement' },
        info = { 'fg', 'PreProc' },
        border = { 'fg', 'Ignore' },
        prompt = { 'fg', 'Conditional' },
        pointer = { 'fg', 'Exception' },
        marker = { 'fg', 'Keyword' },
        spinner = { 'fg', 'Label' },
        header = { 'fg', 'Comment' },
      }
    end,
  },
}


