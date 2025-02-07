local utils = require("smartsessions.utils")
local M = {}

M.file = "data.vim"

---@param session_opts SessionOpts
function M.save(session_opts)
  utils.call_cmd("mks! " .. session_opts.session_path)
end

---@param session_opts SessionOpts
function M.load(session_opts)
  utils.call_cmd("source " .. session_opts.session_path)
end

return M
