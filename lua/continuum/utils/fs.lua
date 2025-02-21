local path = require("plenary.path")
local logger = require("continuum.logger.logger")

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

---@param dir_path string
---@param message? string
function M.remove_dir(dir_path, message)
  local dir = path:new(dir_path)

  if not dir:exists() then
    return false, "Directory does not exist"
  end

  local confirm = vim.fn.input((message or "Remove directory and all contents?") .. " (y/N): ")
  if confirm:lower() ~= "y" then
    return false, "Operation cancelled"
  end

  local success, err = pcall(function()
    dir:rm({ recursive = true })
  end)

  return success, err
end

---@param file_path string
---@param data any
---@return boolean
function M.write_json_file(file_path, data)
  local file = io.open(file_path, "w")
  if not file then
    return false
  end
  local content = vim.json.encode(data)
  file:write(content)
  file:close()
  return true
end

---@param file_path string
---@return any
function M.read_json_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return vim.json.decode(content)
end

return M
