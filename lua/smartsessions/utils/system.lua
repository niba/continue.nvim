local logger = require("smartsessions.logger.logger")
local M = {}

---@param command string
---@param log_level? integer
function M.call_cmd(command, log_level)
  local success, result = pcall(function()
    vim.cmd(command)
  end)

  if not success then
    local error = string.format("Calling %s command caused error: %s", command, result)
    logger.log(log_level or vim.log.levels.DEBUG, error)
    return nil, error
  end

  return result, nil
end

---@param command string
---@param log_level? integer
function M.call_shell(command, log_level)
  local result = vim.fn.system(command)
  local exit_code = vim.v.shell_error
  if exit_code ~= 0 then
    local error =
      string.format("Calling %s system caused error [%d]: %s", command, exit_code, result)
    logger.log(log_level or vim.log.levels.DEBUG, error)
    return nil, error
  end
  return result, nil
end

return M
