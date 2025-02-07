local utils = require("smartsessions.utils")
local M = {}

M.file = "data.shada"

function M.configuration()
  vim.o.shada = ""
end

local local_shada_options = "'100,<50,s10,h,:0,/1000"
local global_shada_options = "!,'0,<0,s10,h,:1000,/0,f0"

---@param session_opts SessionOpts
function M.save(session_opts)
  vim.o.shada = global_shada_options
  utils.call_cmd("wshada" .. session_opts.global_path)
  vim.o.shada = local_shada_options
  utils.call_cmd("wshada!" .. session_opts.session_path)
  vim.o.shada = ""
end

---@param session_opts SessionOpts
function M.load(session_opts)
  utils.call_cmd("clearjumps")
  vim.o.shada = global_shada_options
  utils.call_cmd("rshada!" .. session_opts.global_path)
  utils.call_cmd("clearjumps")
  vim.o.shada = local_shada_options
  utils.call_cmd("rshada" .. session_opts.session_path)
  vim.o.shada = ""
end

return M
