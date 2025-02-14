local logger_adapters = require("continuum.logger.adapters")

local reversed_levels = {}
for k, v in pairs(vim.log.levels) do
  reversed_levels[v] = k
end

local function formatter(level, msg, ...)
  local args = vim.F.pack_len(...)
  for i = 1, args.n do
    local v = args[i]
    if type(v) == "table" then
      args[i] = vim.inspect(v)
    elseif v == nil then
      args[i] = "nil"
    end
  end
  local ok, text = pcall(string.format, msg, vim.F.unpack_len(args))

  if ok then
    local str_level = reversed_levels[level]
    return string.format("[%s] %s: %s", str_level, os.date("%Y-%m-%d %H:%M:%S"), text)
  else
    return string.format("[ERROR] error formatting log line: '%s' args %s", msg, vim.inspect(args))
  end
end

---@class AdapterConfig
---@field level? integer
---@field name string

---@class AdapterInstance
---@field level integer
---@field adapter LogAdapter

---@class Logger
---@field adapters AdapterInstance[]
---@field allowance_level integer
local Logger = {}

---@class LoggerOpts
---@field adapters AdapterConfig[]
---@field level integer
---@field prefix string

---@param opts LoggerOpts
function Logger.new(opts)
  local adapters = {}

  for _, defn in ipairs(opts.adapters) do
    local adapter = nil

    if defn.name == logger_adapters.ADAPTER_TYPES.file then
      adapter = logger_adapters.create_file_adapter(opts.prefix .. ".log")
    elseif defn.name == logger_adapters.ADAPTER_TYPES.notifier then
      adapter = logger_adapters.create_notifier_adapter(opts.prefix)
    end

    table.insert(adapters, {
      adapter = adapter,
      level = defn.level,
    })
  end

  Logger.adapters = adapters
  Logger.allowance_level = opts.level
  Logger.initialized = true

  return Logger
end

function Logger.destroy()
  for _, adapter in ipairs(Logger.adapters) do
    if adapter.adapter.destroy then
      adapter.adapter.destroy()
    end
  end
end

---@param level integer
---@param msg string
function Logger.log(level, msg, ...)
  if not Logger.initialized == true then
    vim.notify("Logger has not been intialized", vim.log.levels.ERROR)
    return
  end

  for _, adapter in ipairs(Logger.adapters) do
    if Logger.allowance_level <= adapter.level then
      adapter.adapter.write(formatter(level, msg, ...), level)
    end
  end
end

---@param msg string
---@param ... any
function Logger.trace(msg, ...)
  Logger.log(vim.log.levels.TRACE, msg, ...)
end

---@param msg string
---@param ... any
function Logger.debug(msg, ...)
  Logger.log(vim.log.levels.DEBUG, msg, ...)
end

---@param msg string
---@param ... any
function Logger.info(msg, ...)
  Logger.log(vim.log.levels.INFO, msg, ...)
end

---@param msg string
---@param ... any
function Logger.warn(msg, ...)
  Logger.log(vim.log.levels.WARN, msg, ...)
end

---@param msg string
---@param ... any
function Logger.error(msg, ...)
  Logger.log(vim.log.levels.ERROR, msg, ...)
end

return Logger
