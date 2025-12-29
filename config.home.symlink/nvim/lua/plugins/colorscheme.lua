-- Colorscheme Configuration
-- Using gruvbox (darktooth was a gruvbox variant from dotfilesold)

return {
  {
    -- Gruvbox colorscheme - warm, retro theme similar to darktooth
    'morhetz/gruvbox',
    lazy = false,
    priority = 1000,
    config = function()
      -- Configure gruvbox settings
      vim.g.gruvbox_contrast_dark = 'medium'  -- Options: soft, medium, hard
      vim.g.gruvbox_italic = 1

      -- Set gruvbox as colorscheme
      vim.cmd([[colorscheme gruvbox]])
      vim.opt.background = 'dark'

      -- Disable overly strict markdown error highlighting
      vim.cmd([[highlight link markdownError NONE]])

      -- Fix diff highlighting to be more transparent and preserve syntax
      -- Use background colors with blend instead of inverse foreground colors
      vim.cmd([[
        highlight DiffAdd    guifg=NONE guibg=#2d3d45 gui=NONE
        highlight DiffChange guifg=NONE guibg=#3d4220 gui=NONE
        highlight DiffDelete guifg=#cc241d guibg=#442e2d gui=NONE
        highlight DiffText   guifg=NONE guibg=#4d4020 gui=bold
      ]])
    end,
  },
}
