local system = require("continue.utils.system")
local logger = require("continue.logger.logger")
local M = {}

M.file = "data.vim"

local function remove_cd_from_session(session_file_path)
  local file = io.open(session_file_path, "r")
  if not file then
    logger.debug("Error: Could not open session file: %s", session_file_path)
    return false
  end

  local lines = {}
  for line in file:lines() do
    if not line:match("^%s*cd%s+") then
      table.insert(lines, line)
    end
  end
  file:close()

  file = io.open(session_file_path, "w")
  if not file then
    logger.debug("Error: Could not open session file for writing: %s", session_file_path)
    return false
  end

  for _, line in ipairs(lines) do
    file:write(line .. "\n")
  end
  file:close()

  return true
end

---@param session_opts SessionOpts
function M.save(session_opts)
  system.call_cmd("mks! " .. session_opts.project_data_path)
  remove_cd_from_session(session_opts.project_data_path)
end

---@param session_opts SessionOpts
function M.load(session_opts)
  vim.cmd("cd " .. session_opts.project_root)
  system.call_cmd("source " .. session_opts.project_data_path)
end

return M
