-- Highlight multiple words in different colors simultaneously

return {
  'Mr-LLLLL/interestingwords.nvim',
  event = 'VeryLazy',
  config = function()
    local iw = require('interestingwords')

    local colors = {
      '#5a5d30', -- olive/yellow-green
      '#5d3838', -- dark red
      '#3a4d58', -- dark blue
      '#6d5030', -- orange/brown
      '#5d5d38', -- yellow-brown
      '#385d5d', -- teal/cyan
      '#4a3a5d', -- dark purple
      '#3a5d3a', -- dark green
      '#5d385d', -- magenta
      '#3a5d4a', -- forest/mint
      '#5d4a30', -- dark amber
      '#30485d', -- steel blue
      '#5d3050', -- plum
      '#48305d', -- indigo
      '#305d48', -- dark seafoam
      '#5d5048', -- taupe
      '#48555d', -- slate
      '#555d48', -- moss
      '#5d4838', -- chestnut
      '#385048', -- dark cyan-green
    }

    iw.setup({
      colors = colors,
      search_count = false,
      navigation = false, -- Disable n/N navigation (belongs to native search)
      color_key = '<leader>hi',
    })

    -- Override highlight groups to preserve syntax colors (like diff highlighting)
    -- Plugin defaults to fg='Black', but we want fg=NONE to preserve syntax highlighting
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
