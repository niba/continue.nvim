require("smartsessions.types")
local logger = require("smartsessions.logger.logger")
local consts = require("smartsessions.consts")
local adapters = require("smartsessions.logger.adapters")
local fs = require("smartsessions.utils.fs")
local git = require("smartsessions.utils.git")
local sessions = require("smartsessions.sessions")
local events = require("smartsessions.utils.events")
local config = require("smartsessions.config")

---@param force_branch_name? string
local function get_session_data(force_branch_name)
  local opts = config.options
  local session_name = sessions.get_name(opts, force_branch_name)

  local session_dir = fs.join_paths(opts.root_dir, session_name)

  return session_dir, session_name
end

---@class core.session
local M = {}
-- preserver

---@param cfg SmartSessions.Config
function M.setup(cfg)
  config.setup(cfg)

  logger.new({
    prefix = consts.PLUGIN_NAME,
    level = vim.log.levels.ERROR,
    adapters = {
      {
        name = adapters.ADAPTER_TYPES.notifier,
        level = vim.log.levels.DEBUG,
      },
      {
        name = adapters.ADAPTER_TYPES.file,
        level = vim.log.levels.DEBUG,
      },
    },
  })

  sessions.configuration()

  if config.options.auto_restore then
    events.on_start(function()
      vim.schedule(function()
        M.load(get_session_data())
        if config.options.auto_restore_on_branch_change and git.is_git_repo() then
          git.watch_branch_changes(function(old_branch_name)
            M.save(get_session_data(old_branch_name))
            M.load(get_session_data())
          end)
          logger.debug("Watching branch changes")
        end
      end)
    end)
  end

  if config.options.auto_save then
    events.on_end(function()
      M.save(get_session_data())
      logger.destroy()
    end)
  else
    events.on_end(function()
      logger.destroy()
    end)
  end
end

---@param session_path string
---@param session_name string
function M.save(session_path, session_name)
  logger.debug("Saving session for cwd [%s] with name [%s]", vim.fn.getcwd(), session_name)
  fs.create_dir(session_path)
  sessions.save(session_path)
  logger.debug("Session [%s] has been saved", session_name)
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

  logger.debug("Loading session for cwd [%s] with name [%s]", vim.fn.getcwd(), session_name)
  sessions.load(session_path)
  logger.debug("Session %s has been loaded", session_name)
end

function M.list()
  local existing_sessions = sessions.list({ all = false })

  vim.ui.select(existing_sessions, {
    prompt = "Select a session:",
    format_item = function(item)
      return item.base .. " " .. item.branch
    end,
  }, function(choice)
    if choice then
      M.load(choice.path, choice.name)
    end
  end)
end

-- :Lazy reload smartsessions
-- lua require("smartsessions").setup()
return M
