local logger = require("smartsessions.logger.logger")
local M = {}
M.format_session_name = function(name)
  return name:gsub("[\\/:]+", "%%")
end

---@param name string
function M.encode(name)
  local encoded_name = string.gsub(name, "([^%w %-%_%.%~])", function(c)
    return string.format("_%02X", string.byte(c))
  end)
  encoded_name = string.gsub(encoded_name, " ", "+")

  logger.trace("Name [%s] has been encdoded to: [%s]", name, encoded_name)
  return encoded_name
end

---@param encoded_name string
function M.decode(encoded_name)
  local name = string.gsub(encoded_name, "+", " ")

  name = string.gsub(name, "_(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)

  logger.trace("Name [%s] has been decoded to: [%s]", encoded_name, name)
  return name
end

return M
