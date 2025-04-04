local system = require("continuum.utils.system")
local config = require("continuum.config")
local M = {}

M.file = "data.shada"

function M.init()
  vim.o.shada = ""
end

---@param session_opts SessionOpts
function M.save(session_opts)
  vim.o.shada = config.options.shada.global
  system.call_cmd("wshada" .. session_opts.global_path)
  vim.o.shada = config.options.shada.project
  system.call_cmd("wshada!" .. session_opts.project_path)
  vim.o.shada = ""
end

---@param session_opts SessionOpts
function M.load(session_opts)
  system.call_cmd("clearjumps")
  vim.o.shada = config.options.shada.global
  system.call_cmd("rshada!" .. session_opts.global_path)
  system.call_cmd("clearjumps")
  vim.o.shada = config.options.shada.project
  system.call_cmd("rshada" .. session_opts.project_path)
  vim.o.shada = ""
end

return M
