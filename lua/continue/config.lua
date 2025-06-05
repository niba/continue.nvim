local utils = require("continue.utils")
local logger = require("continue.logger.logger")
local git = require("continue.utils.git")
local fs = require("continue.utils.fs")
local consts = require("continue.consts")

local M = {}

---@class Continue.Config
M.default = {
  auto_restore = true,
  auto_save = true,
  auto_save_min_buffer = 1,
  auto_restore_on_branch_change = true,

  react_on_cwd_change = false,
  use_git_branch = true,
  use_git_host = true,
  log_level = vim.log.levels.WARN,
  root_dir = fs.join_paths(vim.fn.stdpath("data"), consts.PLUGIN_NAME),
  picker = "snacks",
  git_remote = "origin",
  shada = {
    project = "'100,<50,s10,h,:0,/1000,f50",
    global = "!,'0,<0,s10,h,:1000,/0,f0",
  },
  mappings = {
    delete_session = { "i", "<C-X>" },
    save_as_session = { "i", "<C-S>" },
  },
  extensions = {},
  hooks = {},
}

---@type Continue.Config
M.options = {}

function M.setup(opts)
  M.options = utils.merge_deep({}, M.default, opts)

  consts.PROCESSING_IS_REPO = true
  git.is_git_repo(function(res, err)
    local is_repo = err == nil
    consts.IS_REPO = is_repo
    consts.PROCESSING_IS_REPO = false

    local forced_options = {}
    if not is_repo then
      if M.options.use_git_branch or M.options.use_git_host then
        logger.debug("Can't use git features on non git repo: %s", vim.uv.cwd())
      end

      forced_options.use_git_branch = false
      forced_options.use_git_host = false
      forced_options.auto_restore_on_branch_change = false
      M.options = utils.merge_deep(M.options, forced_options)
    end
  end)

  fs.create_dir(M.options.root_dir)
end

return M
