local logger = require("continuum.logger.logger")
local fs = require("continuum.utils.fs")
local custom_qf = require("continuum.sessions.custom.quickfix")
local custom_cc = require("continuum.sessions.custom.codecompanion")
local M = {}

M.file = "data.json"

local builtin = {
  qf = custom_qf,
  codecompanion = custom_cc,
}

---@type table<string, Continuum.CustomHandler>
local handlers = {}

---@param handler Continuum.CustomHandler
function M.register(handler)
  handlers[handler.id] = {
    load = handler.load,
    save = handler.save,
    config = handler.config,
    id = handler.id,
  }
end

---@param opts Continuum.Config
function M.init(opts)
  for key, value in pairs(opts.custom_builtin or {}) do
    if value and builtin[key].condition() then
      M.register(builtin[key])
    end
  end
  for key, value in pairs(opts.custom) do
    if value then
      M.register(value())
    end
  end
end

---@param session_opts SessionOpts
function M.save(session_opts)
  local handlers_data = {}

  for handler_name, handler in pairs(handlers) do
    if handler.save then
      local success, handler_data = pcall(function()
        return handler.save(session_opts)
      end)
      if not success then
        logger.error("Error while saving custom session data: %s", handler_data)
      end
      if success then
        local can_be_json, encoding_result = pcall(function()
          vim.json.encode(handler_data)
        end)

        if not can_be_json then
          logger.error(
            "Data encoded by handler %s cannot be saved: %s",
            handler.id,
            encoding_result
          )
        else
          handlers_data[handler_name] = handler_data
        end
      end
    end
  end

  return fs.write_json_file(session_opts.project_data_path, handlers_data)
end

---@param session_opts SessionOpts
function M.load(session_opts)
  local success, data = pcall(function()
    return fs.read_json_file(session_opts.project_data_path)
  end)

  if not success then
    logger.error("Custom session data got corrupted. Can't load it")
    return
  end

  if data == nil then
    logger.info("No data for custom session")
    return
  end

  for key, value in pairs(data) do
    local handler = handlers[key]
    if handler and handler.load then
      pcall(function()
        handler.load(value, session_opts)
      end)
    end
  end
end

return M
