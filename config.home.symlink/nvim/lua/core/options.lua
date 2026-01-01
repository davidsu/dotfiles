-- Core Neovim Options
-- Loaded for all environments (VSCode/Cursor and terminal)

local env = require('core.env')
local opt = vim.opt

-- General
opt.compatible = false
opt.autoread = true              -- detect when a file is changed
opt.autowriteall = true          -- auto-write on various commands
opt.hidden = true                -- allow buffers to be hidden
opt.history = 2000
opt.backspace = { 'indent', 'eol', 'start' }

-- Clipboard
opt.clipboard = 'unnamedplus'    -- use system clipboard

-- Display
opt.number = false               -- no line numbers by default (VSCode has its own)
opt.relativenumber = false
opt.wrap = false                 -- no line wrapping
opt.linebreak = true             -- soft wrap at word boundaries
opt.showbreak = '↪'
opt.scrolloff = 3                -- lines of context around cursor
opt.showcmd = false              -- no show commands by default (VSCode has its own)
opt.showmode = false             -- don't show mode (for statusline)
opt.laststatus = 0               -- no statusline by default (VSCode has its own)
opt.title = true                 -- set terminal title
opt.visualbell = true
opt.errorbells = false
opt.lazyredraw = true            -- don't redraw during macros

-- Colors
opt.termguicolors = true
opt.background = 'dark'

-- Indentation
opt.expandtab = true             -- use spaces instead of tabs
opt.smarttab = true
opt.tabstop = 4                  -- visual width of tabs
opt.softtabstop = 4
opt.shiftwidth = 2               -- number of spaces for indent
opt.shiftround = true            -- round indent to multiple of shiftwidth
opt.autoindent = true
opt.smartindent = true

-- Search
opt.ignorecase = true            -- case insensitive search
opt.smartcase = true             -- case-sensitive if pattern contains uppercase
opt.magic = true                 -- special chars in search patterns

-- Files & Backups
opt.undofile = true              -- persistent undo
opt.backup = false
opt.writebackup = false
opt.swapfile = false

-- Completion
opt.completeopt = { 'menu', 'menuone', 'noselect', 'longest' }
opt.wildmenu = true              -- enhanced command line completion
opt.wildmode = 'full'
opt.wildignorecase = true        -- case-insensitive command-line completion and history

-- Folding
opt.foldmethod = 'manual'  -- Default to manual folding
opt.foldnestmax = 10
opt.foldenable = true
opt.foldlevelstart = 99  -- Start with all folds open

-- Configure folding for specific filetypes
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact', 'tsx', 'jsx' },
  callback = function()
    -- Try TreeSitter folding first, fall back to syntax
    local ok = pcall(function()
      vim.opt_local.foldmethod = 'expr'
      vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end)
    if not ok then
      -- Fall back to syntax-based folding
      vim.opt_local.foldmethod = 'syntax'
    end
    vim.opt_local.foldenable = true
    vim.opt_local.foldlevelstart = 99
  end,
})

-- Markdown uses manual folding (for preview compatibility)
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown' },
  callback = function()
    vim.opt_local.foldmethod = 'manual'
    vim.opt_local.foldenable = false
  end,
})

-- Performance
opt.updatetime = 300
opt.timeoutlen = 500
opt.ttyfast = true

-- Diff
opt.diffopt:append('vertical')
opt.diffopt:append('iwhite')

-- Misc
opt.textwidth = 1000
opt.helpheight = 39
opt.cmdheight = 1
opt.previewheight = 15
opt.sessionoptions:remove('folds')

-- List characters (for when 'list' is enabled)
opt.listchars = {
  tab = '→ ',
  eol = '¬',
  trail = '⋅',
  extends = '❯',
  precedes = '❮',
}
opt.list = false                 -- disabled by default
opt.spell = false                -- spell check disabled (from dotfilesold)

-- Grep
if vim.fn.executable('rg') == 1 then
  opt.grepprg = 'rg --vimgrep --smart-case --follow'
  opt.grepformat = '%f:%l:%c:%m'
elseif vim.fn.executable('ag') == 1 then
  opt.grepprg = 'ag --vimgrep $*'
  opt.grepformat = '%f:%l:%c:%m'
end

-- Load terminal-only options
if not env.is_vscode then
  require('core.options_terminal')
end
