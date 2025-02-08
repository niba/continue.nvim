local system = require("smartsessions.utils.system")
local M = {}

M.file = "data.vim"

---@param session_opts SessionOpts
function M.save(session_opts)
  system.call_cmd("mks! " .. session_opts.project_path)
end

---@param session_opts SessionOpts
function M.load(session_opts)
  system.call_cmd("source " .. session_opts.project_path)
end

return M
