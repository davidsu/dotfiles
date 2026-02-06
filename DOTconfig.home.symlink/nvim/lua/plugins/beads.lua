-- Beads viewer plugin configuration
return {
  dir = vim.fn.stdpath("config") .. "/lua/beads",
  name = "beads",
  config = function()
    require("beads.viewer").setup()
  end,
  cmd = { "Beads", "BeadsRefresh", "BeadsFind" },
  keys = {
    { "1b", "<cmd>Beads<CR>", desc = "Toggle Beads viewer" },
    { "<space>bf", "<cmd>BeadsFind<CR>", desc = "Find current bead in viewer" },
  },
}
