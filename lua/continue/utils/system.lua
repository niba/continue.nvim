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

---@param command string[]
---@param timeout? number
function M.call_shell(command, timeout)
  local result = vim.system(command, { timeout = timeout or 1000 }):wait()

  local out = result.stdout and vim.trim(result.stdout) or ""

  if result.code ~= 0 or out == "" then
    local error = string.format(
      "Calling [%s] command caused error [%d]: %s",
      command,
      result.code,
      result.stderr
    )
    logger.log(vim.log.levels.DEBUG, error)
    return nil
  end

  return out
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
