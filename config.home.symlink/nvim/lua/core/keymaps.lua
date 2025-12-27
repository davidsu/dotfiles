-- Core Keymaps
-- Universal keymaps loaded in all environments

local map = vim.keymap.set
local opts = { silent = true, noremap = true }

-- Save file
map('n', '<space><space>', '<cmd>update<cr>', { desc = 'Save file', silent = true })
map('v', '<space><space>', '<cmd>update<cr>', { desc = 'Save file', silent = true })

-- Better movement (visual lines)
map('n', 'j', 'gj', { silent = true })
map('n', 'k', 'gk', { silent = true })

-- Simple window navigation (Ctrl + hjkl)
map('n', '<C-h>', '<cmd>wincmd h<cr>', { desc = 'Move to left window', silent = true })
map('n', '<C-j>', '<cmd>wincmd j<cr>', { desc = 'Move to down window', silent = true })
map('n', '<C-k>', '<cmd>wincmd k<cr>', { desc = 'Move to up window', silent = true })
map('n', '<C-l>', '<cmd>wincmd l<cr>', { desc = 'Move to right window', silent = true })
map('n', '<C-p>', '<cmd>wincmd p<cr>', { desc = 'Move to previous window', silent = true })

-- Smart window navigation (creates splits at edges)
local win_utils = require('utils.window')
map('n', 'gh', function() win_utils.win_move('h') end, { desc = 'Move/split left', silent = true })
map('n', 'gj', function() win_utils.win_move('j') end, { desc = 'Move/split down', silent = true })
map('n', 'gk', function() win_utils.win_move('k') end, { desc = 'Move/split up', silent = true })
map('n', 'gl', function() win_utils.win_move('l') end, { desc = 'Move/split right', silent = true })

-- Close window
map('n', '\\w', '<cmd>wincmd q<cr>', { desc = 'Close window' })
map('n', '\\q', '<cmd>q<cr>', { desc = 'Quit' })

-- Quick window management
map('n', '1o', '<cmd>only<cr>', { desc = 'Only this window' })

-- Close various windows
map('n', '<space>qq', '<cmd>helpclose<cr><cmd>pclose<cr><cmd>cclose<cr><cmd>lclose<cr>', { desc = 'Close all helper windows' })
map('n', '<space>ql', '<cmd>lclose<cr>', { desc = 'Close location list' })
map('n', '<space>qc', '<cmd>cclose<cr>', { desc = 'Close quickfix' })
map('n', '<space>qp', '<cmd>pclose<cr>', { desc = 'Close preview' })
map('n', '<space>qh', '<cmd>helpclose<cr>', { desc = 'Close help' })

-- Open quickfix/location list
map('n', '<space>oc', '<cmd>copen<cr>', { desc = 'Open quickfix' })
map('n', '<space>ol', '<cmd>lopen<cr>', { desc = 'Open location list' })

-- Search (visual mode with very magic)
map('v', '/', '/\\v', { desc = 'Search very magic' })
map('v', '?', '?\\v', { desc = 'Search backward very magic' })

-- Substitute
map('n', '\\s', ':%s/\\v', { desc = 'Substitute' })
map('v', '\\s', ':s/\\v', { desc = 'Substitute selection' })

-- Redraw
map('n', '\\d', '<cmd>redraw!<cr>', { desc = 'Redraw screen' })

-- Blackhole register shortcuts
map('n', '\\\\', '"_', { desc = 'Blackhole register' })
map('v', '\\\\', '"_', { desc = 'Blackhole register' })

-- Marks (prefer exact position)
map('n', "'", '`', { desc = 'Jump to mark exact position' })

-- Filetype detection
map('n', '<space>fd', '<cmd>filetype detect<cr>', { desc = 'Detect filetype' })

-- History navigation
map('n', '1:', '<cmd>History:<cr>', { desc = 'Command history' })
map('n', '1;', '<cmd>History:<cr>', { desc = 'Command history' })
map('n', '1/', '<cmd>History/<cr>', { desc = 'Search history' })

-- Quick command access
map('n', '\\c', '<cmd>Commands<cr>', { desc = 'Commands' })

-- Execute current line
map('n', '<space>gx', 'm`0y$:@"<cr><c-o>', { desc = 'Execute current line' })

-- Window resizing (smart auto-detection of split orientation)
map('n', '+', function() win_utils.win_size('+') end, { desc = 'Increase window size', silent = true })
map('n', '_', function() win_utils.win_size('-') end, { desc = 'Decrease window size', silent = true })
map('n', '≠', function() win_utils.win_size('+') end, { desc = 'Increase window size (Alt+=)', silent = true })
map('n', '–', function() win_utils.win_size('-') end, { desc = 'Decrease window size (Alt+-)', silent = true })

-- Toggle resize mode (horizontal vs vertical)
map('n', '<space>v', win_utils.toggle_force_horizontal_resize, { desc = 'Toggle resize mode', silent = true })
map('n', '<space>is', win_utils.toggle_force_horizontal_resize, { desc = 'Invert split resizing', silent = true })
map('n', '\\x', win_utils.toggle_force_horizontal_resize, { desc = 'Toggle resize mode', silent = true })
map('n', 'º', win_utils.toggle_force_horizontal_resize, { desc = 'Toggle resize mode (Alt+0)', silent = true })


