-- Text Editing Plugins
-- Loaded in all environments (VSCode/Cursor and terminal)

return {
  -- Surround text objects with quotes, brackets, etc.
  {
    'tpope/vim-surround',
    event = 'VeryLazy',
  },

  -- Comment/uncomment code
  {
    'tpope/vim-commentary',
    event = 'VeryLazy',
  },

  -- Repeat plugin operations with .
  {
    'tpope/vim-repeat',
    event = 'VeryLazy',
  },
}


