local logger = require("continue.logger.logger")
local M = {}

---@param command string
---@param log_level? integer
function M.call_cmd(command, log_level)
  local success, result = pcall(function()
    vim.cmd(command)
  end)

  if not success then
    local error = string.format("Calling [%s] command caused error: %s", command, result)
    logger.log(log_level or vim.log.levels.DEBUG, error)
    return nil, error
  end

  return result, nil
end

---@param command string
function M.call_shell(command)
  local result = vim.fn.system(command)
  local exit_code = vim.v.shell_error
  if exit_code ~= 0 then
    local error =
      string.format("Calling [%s] command caused error [%d]: %s", command, exit_code, result)
    logger.log(vim.log.levels.DEBUG, error)
    return nil, error
  end
  return result, nil
end

---@param command table<string>
---@param callback function
function M.call_shell_cb(command, callback)
  vim.system(command, {
    text = true,
  }, function(obj)
    if obj.code ~= 0 then
      local error = string.format(
        "Calling [%s] command caused error [%d]: %s",
        vim.inspect(command),
        obj.code,
        obj.stderr or ""
      )
      logger.log(vim.log.levels.DEBUG, error)
      callback(nil, error)
    else
      callback(obj.stdout, nil)
    end
  end)
end

function M.is_pager_mode()
  return vim.g.in_pager_mode == 1
end

return M
