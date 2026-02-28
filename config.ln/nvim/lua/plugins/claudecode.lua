-- Claude Code IDE integration via WebSocket MCP protocol

local socket_path = "/tmp/nvim" .. vim.fn.getpid()

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  cmd = { "ClaudeCode", "Cyolo" },
  init = function()
    vim.api.nvim_create_user_command("Cyolo", function()
      vim.cmd("ClaudeCode --dangerously-skip-permissions")
    end, { desc = "Claude Code (skip permissions)" })
  end,
  opts = {
    env = { NVIM_SOCKET_PATH = socket_path },
    terminal = {
      split_width_percentage = 0.50,
    },
  },
  config = function(_, opts)
    -- Start RPC socket so the embedded Claude can control this Neovim via neovim-mcp
    vim.fn.serverstart(socket_path)
    require("claudecode").setup(opts)
  end,
  keys = {
    { "<leader>a",  nil,                              desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v",                  desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
    },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
  },
}
