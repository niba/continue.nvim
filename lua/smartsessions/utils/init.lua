local logger = require("smartsessions.logger.logger")
local M = {}

-- @param event string
-- @param data? table
function M.emit(event, data)
  vim.api.nvim_exec_autocmds("User", { pattern = "Test" .. event, data = data or {} })
end


---@param ... table Tables to merge
---@return table merged_table
M.merge = function(...)
  return vim.tbl_extend("force", unpack({ ... }))
end

---@param ... table Tables to merge
---@return table merged_table
M.merge_deep = function(...)
  return vim.tbl_deep_extend("force", unpack({ ... }))
end


function M.split(text, separator)
  local parts = {}
  local start_index = 1
  while true do
    local sep_start, sep_end = string.find(text, separator, start_index, true)
    if sep_start then
      local part = string.sub(text, start_index, sep_start - 1)
      table.insert(parts, part)
      start_index = sep_end + 1
    else
      local part = string.sub(text, start_index)
      table.insert(parts, part)
      break
    end
  end
  return parts
end


function M.is_windows()
  return string.find(vim.loop.os_uname().sysname, "Windows") ~= nil
end

return M
