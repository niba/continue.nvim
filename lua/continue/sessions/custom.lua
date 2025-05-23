local logger = require("continue.logger.logger")
local fs = require("continue.utils.fs")
local M = {}

M.file = "data.json"

---@type table<string, Continue.CustomHandler>
local handlers = {}

---@param handler Continue.CustomHandler
function M.register(handler)
  handlers[handler.id] = {
    load = handler.load,
    save = handler.save,
    config = handler.config,
    id = handler.id,
    condition = handler.condition,
    init = handler.init,
  }
end

---@param opts Continue.Config
function M.init(opts)
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
