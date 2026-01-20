-- Get all listed buffers excluding quickfix (returns buffer numbers)
local function get_listed_buffers()
  local buffers = {}
  for bufnr = 1, vim.fn.bufnr("$") do
    if vim.fn.buflisted(bufnr) == 1 and vim.fn.getbufvar(bufnr, "&filetype") ~= "qf" then
      table.insert(buffers, bufnr)
    end
  end
  return buffers
end

-- Sort buffers by most recently used
local function sort_by_mru(buffers)
  table.sort(buffers, function(a, b)
    local a_time = vim.fn.getbufinfo(a)[1].lastused
    local b_time = vim.fn.getbufinfo(b)[1].lastused
    return a_time > b_time
  end)
  return buffers
end

-- Get the next buffer to switch to and its alternate
local function get_next_and_alternate_buffers(sorted_buffers)
  local SECOND_MRU_INDEX = 2
  local next_buffer = sorted_buffers[SECOND_MRU_INDEX]

  -- Alternate is third buffer if available, otherwise second
  local alternate_index = #sorted_buffers > SECOND_MRU_INDEX and SECOND_MRU_INDEX + 1 or SECOND_MRU_INDEX
  local alternate_buffer = sorted_buffers[alternate_index]

  return next_buffer, alternate_buffer
end

-- Switch to buffer and delete the previous one
local function switch_and_delete_buffer(next_bufnr, alternate_bufnr)
  vim.cmd("buffer " .. next_bufnr)

  -- Try BD command first (better buffer delete), fallback to bdelete
  local ok, _ = pcall(function()
    vim.cmd("BD")
  end)
  if not ok then
    vim.cmd("bdelete! #")
  end

  -- Set alternate file
  if alternate_bufnr then
    vim.fn.setreg("#", vim.fn.bufname(alternate_bufnr))
  end
end

-- Delete current buffer and switch to next MRU buffer
local function delete_current_buffer()
  local sorted_buffers = sort_by_mru(get_listed_buffers())

  if #sorted_buffers <= 1 then
    print("last buffer")
    return
  end

  local next_bufnr, alternate_bufnr = get_next_and_alternate_buffers(sorted_buffers)
  switch_and_delete_buffer(next_bufnr, alternate_bufnr)
end

return {
  delete_current_buffer = delete_current_buffer,
}
