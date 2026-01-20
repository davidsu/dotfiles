-- Highlight multiple words in different colors simultaneously

return {
  'Mr-LLLLL/interestingwords.nvim',
  event = 'VeryLazy',
  config = function()
    local iw = require('interestingwords')

    iw.setup({
      colors = {
        '#5a5d30', -- brighter olive/yellow-green
        '#5d3838', -- brighter dark red
        '#3a4d58', -- brighter dark blue
        '#6d5030', -- brighter orange/brown
        '#5d5d38', -- brighter yellow-brown
        '#385d5d', -- brighter teal/cyan
      },
      search_count = false,
      navigation = false, -- Disable n/N navigation (belongs to native search)
      color_key = '<leader>hi',
    })

    -- Override highlight groups to preserve syntax colors (like diff highlighting)
    -- Plugin defaults to fg='Black', but we want fg=NONE to preserve syntax highlighting
    local colors = { '#5a5d30', '#5d3838', '#3a4d58', '#6d5030', '#5d5d38', '#385d5d' }
    for i, bg_color in ipairs(colors) do
      vim.api.nvim_set_hl(0, 'InterestingWord' .. i, { bg = bg_color, fg = 'NONE' })
    end

    -- Override <leader>hc to clear both interestingwords AND native search highlights
    vim.keymap.set('n', '<leader>hc', function()
      iw.UncolorAllWords(false) -- false = only clear interestingwords, not search register
      vim.cmd('nohlsearch')
    end, { desc = 'Clear all highlights', silent = true })
  end,
}
