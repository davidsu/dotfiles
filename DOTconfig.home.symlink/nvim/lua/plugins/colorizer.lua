-- nvim-colorizer.lua - Color highlighter
-- Shows colors inline for hex codes, RGB values, etc.
-- Modern maintained fork by NvChad team

return {
  {
    'NvChad/nvim-colorizer.lua',
    event = 'BufReadPre',
    opts = {
      filetypes = { '*' },
      user_default_options = {
        RGB = true,      -- #RGB hex codes
        RRGGBB = true,   -- #RRGGBB hex codes
        names = true,    -- "Name" codes like Blue or blue
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        AARRGGBB = true, -- 0xAARRGGBB hex codes
        rgb_fn = true,   -- CSS rgb() and rgba() functions
        hsl_fn = true,   -- CSS hsl() and hsla() functions
        css = true,      -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true,   -- Enable all CSS *functions*: rgb_fn, hsl_fn
        mode = 'background', -- Set the display mode (foreground, background, virtualtext)
        tailwind = false, -- Enable tailwind colors (not needed)
        sass = { enable = false }, -- Enable sass colors (not needed)
        virtualtext = '■',
      },
    },
  },
}
