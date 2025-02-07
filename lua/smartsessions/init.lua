require("smartsessions.types")
local logger = require("smartsessions.logger.logger")
local consts = require("smartsessions.consts")
local adapters = require("smartsessions.logger.adapters")
local fs = require("smartsessions.fs")
local git = require("smartsessions.utils.git")
local sessions = require("smartsessions.sessions")
local events = require("smartsessions.events")
local config = require("smartsessions.config")

---@param git_branch? string
---@return SessionOpts
local function get_dirs(git_branch)
  local session_name = sessions.create_name({
    useGitHost = config.options.useGitHost,
    useBranchName = config.options.useBranch,
  }, git_branch)

  local data_dir = fs.get_data_dir()
  local session_dir = fs.join_paths(data_dir, session_name)

  return { session_path = session_dir, global_path = data_dir }
end

---@class core.session
local M = {}
-- preserver

---@param cfg SmartSessions.Config
function M.setup(cfg)
  config.setup(cfg)

  logger.new({
    prefix = consts.PLUGIN_NAME,
    level = vim.log.levels.DEBUG,
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
  events.on_start(function()
    vim.schedule(function()
      local dirs = get_dirs()
      -- WORK: refactor
      M.load(dirs.session_path)
      git.watch_branch_changes(function(old_branch_name)
        print("branch changed %s", old_branch_name)
        M.save(old_branch_name)
        local new_dirs = get_dirs()
        M.load(new_dirs.session_path)
      end)
    end)
  end)
  events.on_end(function()
    M.save()
    logger.destroy()
  end)
end

---@param git_branch? string
function M.save(git_branch)
  local dirs = get_dirs(git_branch)

  logger.debug("Saving session %s", dirs.session_path)
  fs.create_dir(dirs.session_path)

  sessions.save(dirs)
  logger.debug("Saved session %s", dirs.session_path)
end

---@param session_dir string
function M.load(session_dir)
  logger.debug("Loading session %s", session_dir)
  sessions.load({ session_path = session_dir, global_path = fs.get_data_dir() })
  logger.debug("Loaded session %s", session_dir)
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
      M.load(choice.path)
    else
      print("No session selected")
    end
  end)
end

-- :Lazy reload smartsessions
-- lua require("smartsessions").setup()
return M
