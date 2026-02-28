-- Colorscheme Configuration
-- Using gruvbox (darktooth was a gruvbox variant from dotfilesold)

local function config()
  vim.g.gruvbox_contrast_dark = 'medium' -- Options: soft, medium, hard
  vim.g.gruvbox_italic = 1

  -- Set gruvbox as colorscheme
  vim.cmd([[colorscheme gruvbox]])
  vim.opt.background = 'dark'

  -- Disable overly strict markdown error highlighting
  vim.cmd([[highlight link markdownError NONE]])

  -- Fix diff highlighting to be more transparent and preserve syntax
  -- DiffChange = line with changes (subtle), DiffText = actual changed chars (prominent)
  vim.cmd([[
        highlight DiffAdd    guifg=NONE guibg=#2d3d45 gui=NONE
        highlight DiffChange guifg=NONE guibg=#3d4220 gui=NONE
        highlight DiffDelete guifg=#cc241d guibg=#442e2d gui=NONE
        highlight DiffText   guifg=NONE guibg=#324f5d gui=NONE
        highlight Visual     guifg=NONE guibg=#4a4a4a gui=NONE
      ]])
end
return {
  {
    -- Gruvbox colorscheme - warm, retro theme similar to darktooth
    'morhetz/gruvbox',
    lazy = false,
    priority = 1000,
    config = config
  },
}
