-- MRU (Most Recently Used) file tracking
-- Tracks recently used files with cursor position

return {
  {
    'nvim-telescope/telescope.nvim',
    optional = true,
    keys = {
      {
        '1m',
        function()
          -- Use MRU custom function
          require('config.mru').show_mru()
        end,
        desc = 'MRU files'
      },
    },
  },
}
