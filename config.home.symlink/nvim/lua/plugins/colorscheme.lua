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
    end,
  },
}
