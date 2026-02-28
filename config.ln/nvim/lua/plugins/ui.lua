-- UI Enhancements

return {
  -- Smooth scrolling
  {
    'psliwka/vim-smoothie',
    event = 'VeryLazy',
  },

  -- Dim inactive windows
  {
    'blueyed/vim-diminactive',
    event = 'VeryLazy',
    config = function()
      vim.g.diminactive_enable_focus = 1
    end,
  },
}
