-- Beads viewer plugin configuration
return {
  dir = vim.fn.stdpath("config") .. "/lua/beads",
  name = "beads",
  config = function()
    require("beads.viewer").setup()
  end,
  cmd = { "Beads", "BeadsRefresh" },
  keys = {
    { "<leader>b", "<cmd>Beads<CR>", desc = "Toggle Beads viewer" },
  },
}
