local path = require("plenary.path")
local logger = require("smartsessions.logger.logger")
local consts = require("smartsessions.consts")

local M = {}

function M.get_data_dir()
  -- WORK: add options to customize directory
  local session_dir = path:new(vim.fn.stdpath("data"), consts.PLUGIN_NAME)
  M.create_dir(session_dir.filename)

  return session_dir.filename
end

---@param base string
---@param ... string
function M.join_paths(base, ...)
  return path:new(base, ...).filename
end

---@param dir_path string
function M.create_dir(dir_path)
  local dir = path:new(dir_path)
  if not dir:exists() then
    logger.debug("created directory %s", dir.filename)
    dir:mkdir({ parents = true, exists_ok = true })
  end
end

return M
