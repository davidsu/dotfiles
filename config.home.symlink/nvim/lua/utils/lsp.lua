-- LSP Utility Functions

-- Helper functions

local function get_lsp_client()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    vim.notify('No LSP client attached', vim.log.levels.WARN)
    return nil
  end

  return clients[1]
end

local function create_preview_window(contents)
  vim.cmd('silent! pclose')
  vim.cmd('pedit [LSP Hover]')
  vim.cmd('wincmd P')

  local preview_bufnr = vim.api.nvim_get_current_buf()

  -- Use LSP's built-in rendering for proper highlighting
  local lines = vim.lsp.util.convert_input_to_markdown_lines(contents)

  vim.api.nvim_buf_set_lines(preview_bufnr, 0, -1, false, lines)
  vim.bo[preview_bufnr].buftype = 'nofile'
  vim.bo[preview_bufnr].bufhidden = 'wipe'
  vim.bo[preview_bufnr].modifiable = false
  vim.bo[preview_bufnr].filetype = 'markdown'
  vim.wo.wrap = true

  vim.cmd('wincmd p')
end

-- Public API

local function is_js_ts_filetype()
  local ft = vim.bo.filetype
  return ft == 'javascript' or ft == 'typescript' or ft == 'javascriptreact' or ft == 'typescriptreact'
end

local function find_signature_position()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Search forward for opening paren on same line
  local paren_col = line:find('%(', col + 1)
  if paren_col then
    -- Return position inside the parens (after opening paren)
    return { line = vim.fn.line('.') - 1, character = paren_col }
  end

  return nil
end

local function hover_preview()
  local client = get_lsp_client()
  if not client then return end

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  local sig_params = params

  -- For JS/TS, try to find signature position if we're on a function name
  if is_js_ts_filetype() then
    local sig_pos = find_signature_position()
    if sig_pos then
      sig_params = vim.lsp.util.make_position_params(0, client.offset_encoding)
      sig_params.position = sig_pos
    end
  end

  local hover_result = nil
  local sig_result = nil
  local responses_received = 0

  local function try_display()
    responses_received = responses_received + 1
    if responses_received < 2 then
      return
    end

    local contents = nil

    -- If we have signatures, format each one like K does
    if sig_result and sig_result.signatures and #sig_result.signatures > 0 then
      local parts = {}

      for i, sig in ipairs(sig_result.signatures) do
        if i > 1 then
          table.insert(parts, '\n---\n\n')
        end

        -- Add signature
        table.insert(parts, '```typescript\n')
        table.insert(parts, sig.label)
        table.insert(parts, '\n```\n')

        -- Add signature documentation
        if sig.documentation then
          table.insert(parts, '\n')
          if type(sig.documentation) == 'string' then
            table.insert(parts, sig.documentation)
          elseif sig.documentation.value then
            table.insert(parts, sig.documentation.value)
          end
          table.insert(parts, '\n')
        end

        -- Add parameter documentation
        if sig.parameters and #sig.parameters > 0 then
          for _, param in ipairs(sig.parameters) do
            table.insert(parts, '\n*@param* `')
            table.insert(parts, param.label)
            table.insert(parts, '`')

            if param.documentation then
              table.insert(parts, ' — ')
              if type(param.documentation) == 'string' then
                table.insert(parts, param.documentation)
              elseif param.documentation.value then
                table.insert(parts, param.documentation.value)
              end
            end
          end
        end
      end

      contents = { kind = 'markdown', value = table.concat(parts) }
    elseif hover_result and hover_result.contents then
      -- Fall back to hover if no signatures
      contents = hover_result.contents
    end

    if not contents then
      vim.notify('No documentation available', vim.log.levels.INFO)
      return
    end

    create_preview_window(contents)
  end

  vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result)
    if not err and result then
      hover_result = result
    end
    try_display()
  end)

  vim.lsp.buf_request(0, 'textDocument/signatureHelp', sig_params, function(err, result)
    if not err and result then
      sig_result = result
    end
    try_display()
  end)
end

return {
  hover_preview = hover_preview,
}
