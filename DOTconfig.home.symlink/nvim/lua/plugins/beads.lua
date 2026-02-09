-- Beads viewer plugin configuration
return {
  dir = vim.fn.stdpath("config") .. "/lua/beads",
  name = "beads",
  config = function()
    vim.api.nvim_set_hl(0, "BeadsCloseReason", { fg = "#e06c75" })
    require("beads.viewer").setup()
  end,
  cmd = { "Beads", "BeadsRefresh", "BeadsFind" },
  keys = {
    { "1b", "<cmd>Beads<CR>", desc = "Toggle Beads viewer" },
    { "<space>bf", "<cmd>BeadsFind<CR>", desc = "Find current bead in viewer" },
  },
}
