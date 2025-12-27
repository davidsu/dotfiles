-- vim-unimpaired - Handy bracket mappings and toggles
-- Loaded in all environments

return {
  {
    'tpope/vim-unimpaired',
    event = 'VeryLazy',
    -- Provides:
    -- Toggle options: cow (wrap), con (number), cor (relativenumber), cos (spell), etc.
    -- Bracket navigation: ]q/[q (quickfix), ]b/[b (buffers), ]a/[a (args), etc.
    -- Paste with auto-indent: >p, >P, etc.
    -- Encode/decode: ]x/[x (XML encode), ]u/[u (URL encode), etc.
  },
}

