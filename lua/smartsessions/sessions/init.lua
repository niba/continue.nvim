local git = require("smartsessions.utils.git")
local utils = require("smartsessions.utils")
local logger = require("smartsessions.logger.logger")
local fs = require("smartsessions.fs")
local consts = require("smartsessions.consts")

local mks = require("smartsessions.sessions.mks")
local shada = require("smartsessions.sessions.shada")
local custom = require("smartsessions.sessions.custom")

local session_providers = {
  mks,
  shada,
  custom,
}

local M = {}

---@param session_opts SessionOpts
function M.load(session_opts)
  -- WORK: only when session exists
  -- do we need to clean all data?
  vim.cmd([[silent! tabonly!]])
  vim.cmd([[silent! %bd!]])
  vim.cmd([[silent! %bw!]])

  for _, provider in ipairs(session_providers) do
    provider.load({
      session_path = fs.join_paths(session_opts.session_path, provider.file),
      global_path = fs.join_paths(session_opts.global_path, provider.file),
    })
  end
end

---@param session_opts SessionOpts
function M.save(session_opts)
  for _, provider in ipairs(session_providers) do
    provider.save({
      session_path = fs.join_paths(session_opts.session_path, provider.file),
      global_path = fs.join_paths(session_opts.global_path, provider.file),
    })
  end
end

function M.configuration()
  for _, provider in ipairs(session_providers) do
    if type(provider.configuration) == "function" then
      provider.configuration()
    end
  end
end

---@param opts { all?: boolean }
function M.list(opts)
  local data_dir = fs.get_data_dir()

  local scan = vim.fn.globpath(data_dir, "*", 0, 1)
  local sessions = {}

  for _, entry in ipairs(scan) do
    if vim.fn.isdirectory(entry) ~= 0 then
      local dir_name = vim.fn.fnamemodify(entry, ":t") -- Get directory name
      local split_parts = utils.split(dir_name, consts.SPECIAL_SEPARATOR)

      table.insert(sessions, {
        base = utils.decode(split_parts[1]),
        branch = split_parts[2] and utils.decode(split_parts[2]) or "",
        path = entry,
      })
    end
  end

  return sessions
end

---@param name string
function M.decode_name(name) end

---@param opts { useGitHost?: boolean; useBranchName?: boolean }
---@param force_git_branch? string
function M.create_name(opts, force_git_branch)
  local parts = {}
  local used_git_host = false

  local response = vim.trim(vim.fn.system("git status"))

  if vim.v.shell_error ~= 0 or response == "" then
    logger.debug("Detecting git repo.  Error code: %d", vim.v.shell_error)
    return nil
  end
  logger.debug("TEST %s", response)
  logger.debug("PWD %s", vim.fn.getcwd())

  if opts.useGitHost then
    local git_host = git.repo_host()
    if not git_host then
      logger.error("Cannot read git host in this repo, fallbacking to cwd")
    else
      table.insert(parts, utils.encode(git_host))
      used_git_host = true
    end
  end

  if not used_git_host then
    local root_path = git.repo_path() or vim.fn.getcwd()
    table.insert(parts, utils.encode(root_path))
  end

  if opts.useBranchName then
    local git_branch = force_git_branch or git.repo_branch()
    if not git_branch then
      logger.error("Cannot detect git branch")
    else
      table.insert(parts, utils.encode(git_branch))
    end
  end
  local name = table.concat(parts, consts.SPECIAL_SEPARATOR)

  logger.debug("generated session name %s", name)
  return name
end

local function get_git_host() end
-- git@github.com:Test-Spec/RandomName.git

return M
