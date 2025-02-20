local utils = require("continuum.utils")
local logger = require("continuum.logger.logger")
local git = require("continuum.utils.git")
local fs = require("continuum.utils.fs")
local consts = require("continuum.consts")

local M = {}

---@class Continuum.Config
M.default = {
  auto_restore = true,
  auto_save = true,
  auto_restore_on_branch_change = true,
  use_git_branch = true,
  use_git_host = true,
  log_level = vim.log.levels.TRACE,
  root_dir = fs.join_paths(vim.fn.stdpath("data"), consts.PLUGIN_NAME),
  mappings = {
    delete_session = { "i", "<C-X>" },
  },
}

---@type Continuum.Config
M.options = {}

function M.setup(opts)
  local user_options = utils.merge_deep({}, M.default, opts)
  local is_repo, error = git.is_git_repo()

  local forced_options = {}
  if error then
    if user_options.use_git_branch or user_options.use_git_host then
      logger.debug("Can't use git features on non git repo: %s", vim.fn.getcwd())
    end

    forced_options.use_git_branch = false
    forced_options.use_git_host = false
    forced_options.auto_restore_on_branch_change = false
  end

  M.options = utils.merge_deep(user_options, forced_options)

  fs.create_dir(M.options.root_dir)
end

return M
