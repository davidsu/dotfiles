-- vim-unimpaired - Handy bracket mappings and toggles
-- Loaded only in terminal (VSCode has native commands)

local env = require('core.env')

if env.is_vscode then
  return {}
end

return {
  {
    'tpope/vim-unimpaired',
    lazy = false,
    -- Provides:
    -- Toggle options: yow (wrap), yon (number), yor (relativenumber), yos (spell), etc.
    -- Bracket navigation: ]q/[q (quickfix), ]b/[b (buffers), ]a/[a (args), etc.
    -- Paste with auto-indent: >p, >P, etc.
    -- Encode/decode: ]x/[x (XML encode), ]u/[u (URL encode), etc.
  },
}

