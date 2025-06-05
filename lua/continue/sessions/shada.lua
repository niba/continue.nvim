local system = require("continue.utils.system")
local config = require("continue.config")
local M = {}

M.file = "data.shada"

function M.init()
  vim.o.shada = ""
end

---@param session_opts SessionOpts
function M.save(session_opts)
  vim.o.shada = config.options.shada.global
  system.call_cmd("wshada" .. session_opts.global_data_path)
  vim.o.shada = config.options.shada.project
  system.call_cmd("wshada!" .. session_opts.project_data_path)
  vim.o.shada = ""
end

local function clear_all_registers()
  for i = string.byte("a"), string.byte("z") do
    vim.fn.setreg(string.char(i), "")
  end

  for i = string.byte("A"), string.byte("Z") do
    vim.fn.setreg(string.char(i), "")
  end

  for i = 0, 9 do
    vim.fn.setreg(tostring(i), "")
  end

  vim.fn.setreg('"', "")
end

---@param session_opts SessionOpts
function M.load(session_opts)
  system.call_cmd("clearjumps")
  vim.fn.histdel("search")
  vim.cmd("delmarks!")
  clear_all_registers()

  vim.o.shada = config.options.shada.project
  system.call_cmd("rshada!" .. session_opts.project_data_path)

  vim.o.shada = config.options.shada.global
  system.call_cmd("rshada" .. session_opts.global_data_path)
  vim.o.shada = ""
end

return M
