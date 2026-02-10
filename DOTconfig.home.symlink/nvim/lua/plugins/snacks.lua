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
      },
    },
  },
}
