-- Core Keymaps
-- Universal keymaps loaded in all environments

local env = require('core.env')
local map = vim.keymap.set
local opts = { silent = true, noremap = true }

-- Save file
map('n', '<space><space>', '<cmd>update<cr>', { desc = 'Save file', silent = true })
map('v', '<space><space>', '<cmd>update<cr>', { desc = 'Save file', silent = true })

-- Better movement (visual lines)
map('n', 'j', 'gj', { silent = true })
map('n', 'k', 'gk', { silent = true })

-- Search (visual mode with very magic)
map('v', '/', '/\\v', { desc = 'Search very magic' })
map('v', '?', '?\\v', { desc = 'Search backward very magic' })

-- Visual star search (search for selected text)
map('v', '*', 'y/\\V<C-R>=escape(@","/\\")<CR><CR>', { desc = 'Search forward for selection' })
map('v', '#', 'y?\\V<C-R>=escape(@","?\\")<CR><CR>', { desc = 'Search backward for selection' })

-- Substitute
map('n', '\\s', ':%s/\\v', { desc = 'Substitute' })
map('v', '\\s', ':s/\\v', { desc = 'Substitute selection' })

-- Blackhole register shortcuts
map('n', '\\\\', '"_', { desc = 'Blackhole register' })
map('v', '\\\\', '"_', { desc = 'Blackhole register' })

-- Marks (prefer exact position)
map('n', "'", '`', { desc = 'Jump to mark exact position' })

-- Execute current line
map('n', '<space>gx', 'm`0y$:@"<cr><c-o>', { desc = 'Execute current line' })

-- Alternate file (switch to last buffer)
map('n', 'm,', '<c-^>', { desc = 'Switch to alternate file' })
map('n', 'sa', '<c-^>', { desc = 'Switch to alternate file' })

-- Help in new tab (command abbreviation)
vim.cmd([[cnoreabbrev <expr> h getcmdtype() == ":" && getcmdline() == 'h' ? 'tab help' : 'h']])

-- Close help/quickfix/fugitive with q
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'help', 'qf', 'fugitiveblame' },
  callback = function()
    vim.keymap.set('n', 'q', '<cmd>bd<cr>', { buffer = true, silent = true })
  end,
})

-- Load terminal-only keymaps
if not env.is_vscode then
  require('core.keymaps_terminal')
end


