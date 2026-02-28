-- Claude Code Integration
-- Commands to connect/disconnect this Neovim instance to Claude Code via MCP

local M = {}

local SOCKET_PATH = '/tmp/nvim'

function M.setup()
  vim.api.nvim_create_user_command('ClaudeConnect', function()
    -- Remove existing socket to take over from any other instance
    vim.fn.delete(SOCKET_PATH)
    vim.fn.serverstart(SOCKET_PATH)
    vim.notify('Claude connected: ' .. SOCKET_PATH)
  end, { desc = 'Connect this Neovim instance to Claude Code' })

  vim.api.nvim_create_user_command('ClaudeDisconnect', function()
    vim.fn.serverstop(SOCKET_PATH)
    vim.notify('Claude disconnected')
  end, { desc = 'Disconnect this Neovim instance from Claude Code' })

  vim.api.nvim_create_user_command('ClaudeStatus', function()
    local servers = vim.fn.serverlist()
    local connected = vim.tbl_contains(servers, SOCKET_PATH)
    if connected then
      vim.notify('Claude: connected (' .. SOCKET_PATH .. ')')
    else
      vim.notify('Claude: not connected')
    end
  end, { desc = 'Check Claude Code connection status' })
end

return M
