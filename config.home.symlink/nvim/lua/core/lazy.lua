-- Lazy.nvim Plugin Manager Bootstrap
-- Auto-installs lazy.nvim if not present

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

-- Auto-install lazy.nvim if not present
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end

-- Add to runtime path
vim.opt.rtp:prepend(lazypath)

-- Configure lazy.nvim
require('lazy').setup('plugins', {
  defaults = {
    lazy = false,  -- by default, load plugins on startup (not lazily)
  },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'matchit',
        'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
  ui = {
    border = 'rounded',
  },
})


