-- UI Enhancements
-- Loaded only in terminal (not needed in VSCode/Cursor)

local env = require('core.env')

if env.is_vscode then
  return {}
end

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


