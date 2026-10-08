-- UI Enhancements

return {
  -- Smooth scrolling
  {
    'declancm/cinnamon.nvim',
    version = '*',
    event = 'VeryLazy',
    opts = {
      keymaps = { basic = true },
      options = { delay = 10, max_delta = { time = 250 } },
    },
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
