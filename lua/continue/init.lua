require("continue.types")
local logger = require("continue.logger.logger")
local consts = require("continue.consts")
local adapters = require("continue.logger.adapters")
local fs = require("continue.utils.fs")
local git = require("continue.utils.git")
local sessions = require("continue.sessions")
local events = require("continue.utils.events")
local config = require("continue.config")
local utils = require("continue.utils")

local picker = require("continue.pickers.picker")

---@class Continue.core
local M = {}

---@param cfg Continue.Config
function M.setup(cfg)
  logger.new({
    prefix = consts.PLUGIN_NAME,
    level = cfg.log_level or config.default.log_level,
    adapters = {
      {
        name = adapters.ADAPTER_TYPES.notifier,
        level = vim.log.levels.INFO,
      },
      {
        name = adapters.ADAPTER_TYPES.file,
        level = vim.log.levels.DEBUG,
      },
    },
  })

  if utils.has_file_as_argument() then
    consts.enable_pager_mode()
  end

  if consts.get_pager_mode() then
    return
  end

  events.register_commands()

  config.setup(cfg)

  sessions.init(config.options)

  if config.options.react_on_cwd_change then
    events.on_cwd_change({
      condition = function()
        if consts.is_auto_session_disabled_by_option() then
          logger.debug(
            "Auto restoring is disabled by option g:auto_continue. Stopping auto restore"
          )
          return false
        end
        if consts.get_pager_mode() then
          logger.debug("Detected pager mode, stopping auto restore")
          return false
        end
        return true
      end,
      before_change = function()
        M.save()
      end,
      after_change = function()
        M.load()
      end,
    })
  end

  events.on_start(function(dir_path)
    vim.wait(200, function()
      return not consts.PROCESSING_IS_REPO
    end)

    if consts.is_auto_session_disabled_by_option() then
      logger.debug("Auto restoring is disabled by option g:auto_continue. Stopping auto restore")
      return false
    end
    if consts.get_pager_mode() then
      logger.debug("Detected pager mode, stopping auto restore")
      return
    end

    if config.options.auto_restore then
      if dir_path then
        -- hack to make auto restore work with neo-tree when starting nvim with a directory path
        vim.cmd("vsplit")
      end

      M.load()
    end

    if config.options.auto_restore_on_branch_change and consts.IS_REPO then
      git.watch_branch_changes(function(old_branch_name)
        M.save(sessions.get_name(config.options, old_branch_name))
        M.load()
      end)
      logger.debug("Watching branch changes")
    end
  end)

  M.toggle_auto_save(config.options.auto_save)

  local cmds = require("continue.commands")
  for _, cmd in ipairs(cmds) do
    vim.api.nvim_create_user_command(cmd.cmd, cmd.callback, cmd.opts)
  end

  events.on_end(function()
    logger.destroy()
  end)

  vim.schedule(function()
    picker.init_pickers()
  end)
end

local auto_save_trigger = nil
---@param force_state? boolean
function M.toggle_auto_save(force_state)
  if force_state == nil then
    config.options.auto_save = not config.options.auto_save
  else
    config.options.auto_save = force_state
  end

  local auto_save = config.options.auto_save

  if auto_save and auto_save_trigger then
    return
  end

  if not auto_save and not auto_save_trigger then
    return
  end

  local auto_save_cb = function()
    if consts.is_auto_session_disabled_by_option() then
      logger.debug("Auto saving is disabled by option g:auto_continue")
      return
    end
    if consts.get_pager_mode() then
      logger.debug("Detected pager mode, stopping auto save")
      return
    end
    if utils.buffers_count() < config.options.auto_save_min_buffer then
      logger.debug("Not enough buffers loaded to auto save")
      return
    end

    M.save()
  end

  if auto_save and not auto_save_trigger then
    auto_save_trigger = events.on_end(auto_save_cb)
  end

  if not auto_save and auto_save_trigger then
    auto_save_trigger()
    auto_save_trigger = nil
  end
end

---@param session_name? string
function M.delete(session_name)
  session_name = session_name or sessions.get_name(config.options)
  local session_path = fs.join_paths(config.options.root_dir, session_name)

  sessions.delete(session_path, session_name)
end

---@param session_name? string
function M.save(session_name)
  session_name = session_name or sessions.get_name(config.options)
  local session_path = fs.join_paths(config.options.root_dir, session_name)

  local start_time = os.time()

  fs.create_dir(session_path)
  sessions.save(session_path)

  local end_time = os.time()
  local elapsed = end_time - start_time
  logger.debug("Session [%s] has been saved, time: %d seconds", session_name, elapsed)
end

---@param session_name? string
function M.load(session_name)
  session_name = session_name or sessions.get_name(config.options)
  local session_path = fs.join_paths(config.options.root_dir, session_name)

  if not fs.dir_exists(session_path) then
    logger.debug(
      "Loading session stopped. There is no data for cwd [%s] and session name [%s]",
      vim.fn.getcwd(),
      session_name
    )
    return
  end

  logger.debug("Loading session for cwd [%s] with name [%s]", vim.fn.getcwd(), session_name)
  local start_time = os.time()
  sessions.load(session_path)
  local end_time = os.time()
  local elapsed = end_time - start_time
  logger.info("Session %s has been loaded, time: %d seconds", session_name, elapsed)
end

---@param opts? Continue.SearchOpts
function M.search(opts)
  picker.sessions({
    all = opts and opts.all or false,
    picker = opts and opts.picker or config.options.picker,
  })
end

return M
