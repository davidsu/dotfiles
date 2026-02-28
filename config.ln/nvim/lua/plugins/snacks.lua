-- Snacks.nvim - folke's collection of small QoL plugins
-- Currently used for: inline image/mermaid rendering in markdown

return {
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        convert = {
          mermaid = { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-t", "dark", "-s", "4" },
        },
        doc = {
          max_width = 120,  -- Increased from default 80
          max_height = 60,  -- Increased from default 40
        },
      },
    },
  },
}
