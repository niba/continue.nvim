require("continuum.types")
local logger = require("continuum.logger.logger")
local consts = require("continuum.consts")
local adapters = require("continuum.logger.adapters")
local fs = require("continuum.utils.fs")
local git = require("continuum.utils.git")
local sessions = require("continuum.sessions")
local events = require("continuum.utils.events")
local config = require("continuum.config")
local utils = require("continuum.utils")
local lsp = require("continuum.lsp")

local picker = require("continuum.pickers.picker")

---@param force_branch_name? string
local function get_session_data(force_branch_name)
  local opts = config.options
  local session_name = sessions.get_name(opts, force_branch_name)

  local session_dir = fs.join_paths(opts.root_dir, session_name)

  return session_dir, session_name
end

---@class Continuum.core
local M = {}

---@param cfg Continuum.Config
function M.setup(cfg)
  logger.new({
    prefix = consts.PLUGIN_NAME,
    level = cfg.log_level or config.default.log_level,
    adapters = {
      {
        name = adapters.ADAPTER_TYPES.notifier,
        level = vim.log.levels.WARN,
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

  if consts.PAGER_MODE then
    return
  end

  events.register_commands()

  config.setup(cfg)

  sessions.init(config.options)

  if config.options.react_on_cwd_change then
    events.on_cwd_change({
      condition = function()
        if consts.PAGER_MODE then
          logger.info("Detected pager mode, stopping auto restore")
          return false
        end
        return true
      end,
      before_change = function()
        M.save(get_session_data())
      end,
      after_change = function()
        M.load(get_session_data())
      end,
    })
  end

  events.on_start(function()
    if config.options.auto_restore then
      if consts.PAGER_MODE then
        -- TODO: change to debug later
        logger.info("Detected pager mode, stopping auto restore")
        return
      end

      M.load(get_session_data())
    end

    picker.init_pickers()

    if config.options.auto_restore_on_branch_change and git.is_git_repo() then
      git.watch_branch_changes(function(old_branch_name)
        M.save(get_session_data(old_branch_name))
        M.load(get_session_data())
      end)
      logger.debug("Watching branch changes")
    end
  end)

  if config.options.auto_save then
    events.on_end(function()
      if consts.PAGER_MODE then
        logger.info("Detected pager mode, stopping auto save")
        return
      end
      if utils.buffers_count() < config.options.auto_save_min_buffer then
        logger.info("Not enough buffers loaded to auto save")
        return
      end

      M.save(get_session_data())
      logger.destroy()
    end)
  else
    events.on_end(function()
      logger.destroy()
    end)
  end
end

function M.reset() end

---@param session_path string
---@param session_name string
function M.save(session_path, session_name)
  logger.debug("Saving session for cwd [%s] with name [%s]", vim.fn.getcwd(), session_name)
  local start_time = os.time()
  fs.create_dir(session_path)
  sessions.save(session_path)
  local end_time = os.time()
  local elapsed = end_time - start_time
  logger.info("testttt")
  logger.info("Session [%s] has been saved, time: %d seconds", session_name, elapsed)
end

---@param session_path string
---@param session_name string
function M.load(session_path, session_name)
  if not fs.dir_exists(session_path) then
    logger.debug(
      "Loading session stopped. There is no data for cwd [%s] and session name [%s]",
      vim.fn.getcwd(),
      session_name
    )
    return
  end

  -- most lsp clients auto attach so we only need to care about stopping it
  -- lsp.stop_lsp()
  logger.debug("Loading session for cwd [%s] with name [%s]", vim.fn.getcwd(), session_name)
  local start_time = os.time()
  sessions.load(session_path)
  local end_time = os.time()
  local elapsed = end_time - start_time
  logger.info("Session %s has been loaded, time: %d seconds", session_name, elapsed)
  -- lsp.stop_lsp()
end

---@param opts? Continuum.SearchOpts
function M.search(opts)
  sessions.search(opts and opts.picker or "snacks")
end

-- :Lazy reload continuum
-- lua require("continuum").setup()
return M
