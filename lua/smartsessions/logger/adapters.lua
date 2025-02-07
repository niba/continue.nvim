local path = require("plenary.path")

local M = {}

M.LEVELS = vim.log.levels
M.ADAPTER_TYPES = {
  file = "file",
  notifier = "notifier",
}

--- @alias AdapetrType 'file' | 'notifier'
---
---@class LogAdapter
---@field name '"file" | "notifier"'
---@field write fun(text: string, level: integer)
---@field destroy? fun()

---@param filename string
---@return LogAdapter
function M.create_file_adapter(filename)
  local ok, stdpath = pcall(vim.fn.stdpath, "log")
  if not ok then
    stdpath = vim.fn.stdpath("cache")
  end
  assert(type(stdpath) == "string")

  -- why filename is a filepath?
  local filepath = path:new(stdpath):joinpath(filename).filename

  local logfile, openerr = io.open(filepath, "a+")

  if not logfile then
    vim.notify(string.format("Failed to open log file: %s", openerr), vim.log.levels.ERROR)
    return {
      name = M.ADAPTER_TYPES.file,
      write = function() end,
    }
  end

  return {
    name = M.ADAPTER_TYPES.file,
    write = function(text, level)
      logfile:write(text)
      logfile:write("\n")
      logfile:flush()
    end,
    destroy = function()
      if logfile then
        logfile:close()
      end
    end,
  }
end

---@param prefix string
---@return LogAdapter
function M.create_notifier_adapter(prefix)
  return {
    name = M.ADAPTER_TYPES.notifier,
    write = function(text, level)
      vim.notify(text, level, { name = prefix })
    end,
  }
end

return M
