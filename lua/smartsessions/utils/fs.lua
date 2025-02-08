local path = require("plenary.path")
local logger = require("smartsessions.logger.logger")

local M = {}

---@param base string
---@param ... string
function M.join_paths(base, ...)
  return path:new(base, ...).filename
end

function M.dir_exists(dir_path)
  local dir = path:new(dir_path)
  return dir:exists()
end

---@param dir_path string
function M.create_dir(dir_path)
  local dir = path:new(dir_path)
  if not dir:exists() then
    logger.debug("created directory %s", dir.filename)
    dir:mkdir({ parents = true, exists_ok = true })
    return true
  end

  return false
end

return M
