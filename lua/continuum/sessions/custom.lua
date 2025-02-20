local logger = require("continuum.logger.logger")
local fs = require("continuum.utils.fs")
local custom_qf = require("continuum.sessions.custom.quickfix")
local custom_cc = require("continuum.sessions.custom.code_companion")
local M = {}

M.file = "data.json"

local function write_json_file(file_path, data)
  local file = io.open(file_path, "w")
  if not file then
    return false
  end
  local content = vim.json.encode(data)
  file:write(content)
  file:close()
  return true
end

---@return table
local function read_json_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return vim.json.decode(content)
end

---@param session_opts SessionOpts
---@param handler Continuum.CustomHandler
local function get_handler_dir(session_opts, handler)
  local handle_dir = fs.join_paths(
    vim.fn.fnamemodify(session_opts.project_path, ":h"),
    string.format("__custom_handler_data_%s", handler.id)
  )
  if handler.config and handler.config.needs_dir then
    fs.create_dir(handle_dir)
  end

  return handle_dir
end

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

function M.configuration(opts)
  M.register(custom_qf)
  M.register(custom_cc)
end

---@param session_opts SessionOpts
function M.save(session_opts)
  local handlers_data = {}

  for handler_name, handler in pairs(handlers) do
    if handler.save then
      local success, handler_data = pcall(function()
        return handler.save({
          dir = handler.config and handler.config.needs_dir and get_handler_dir(
            session_opts,
            handler
          ) or nil,
        })
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

  logger.info("writin custom data %s", handlers_data)
  return write_json_file(session_opts.project_path, handlers_data)
end

---@param session_opts SessionOpts
function M.load(session_opts)
  local success, data = pcall(function()
    return read_json_file(session_opts.project_path)
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
      logger.info("Calling custom %s to load data", handler.id)
      pcall(function()
        handler.load(value, {
          dir = handler.config and handler.config.needs_dir and get_handler_dir(
            session_opts,
            handler
          ) or nil,
        })
      end)
    end
  end
end

return M
