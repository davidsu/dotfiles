-- Plugin Loader
-- Aggregates all plugin modules for lazy.nvim

return {
  -- Import all plugin modules
  { import = 'plugins.editing' },
  { import = 'plugins.git' },
  { import = 'plugins.fzf' },
  { import = 'plugins.tree' },
  { import = 'plugins.statusline' },
  { import = 'plugins.ui' },
  { import = 'plugins.unimpaired' },
}


