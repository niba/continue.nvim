local logger = require("continuum.logger.logger")
local M = {}

-- @param event string
-- @param data? table
function M.emit(event, data)
  vim.api.nvim_exec_autocmds("User", { pattern = "Test" .. event, data = data or {} })
end

---@param ... table Tables to merge
---@return table merged_table
M.merge = function(...)
  local num_args = select("#", ...)
  local args = {}
  for i = 1, num_args do
    local arg = select(i, ...)
    if arg == nil then
      args[i] = {}
    else
      args[i] = arg
    end
  end

  return vim.tbl_extend("force", unpack(args))
end

---@param ... table Tables to merge
---@return table merged_table
M.merge_deep = function(...)
  local num_args = select("#", ...)
  local args = {}
  for i = 1, num_args do
    local arg = select(i, ...)
    if arg == nil then
      args[i] = {}
    else
      args[i] = arg
    end
  end

  return vim.tbl_deep_extend("force", unpack(args))
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

function M.has_file_as_argument()
  local args = vim.fn.argv()

  for _, arg in ipairs(args) do
    if not arg:match("^[+-]") and arg ~= "-" then
      if vim.fn.isdirectory(arg) == 0 then
        return true
      end
    end
  end

  return false
end

return M
