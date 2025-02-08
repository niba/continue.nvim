local git = require("smartsessions.utils.git")
local utils = require("smartsessions.utils")
local config = require("smartsessions.config")
local encoding = require("smartsessions.utils.encoding")
local logger = require("smartsessions.logger.logger")
local fs = require("smartsessions.utils.fs")
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

---@param session_path string
function M.load(session_path)
  -- TODO: do we need to reset ui?
  vim.cmd([[silent! tabonly!]])
  vim.cmd([[silent! %bd!]])
  vim.cmd([[silent! %bw!]])

  for _, provider in ipairs(session_providers) do
    provider.load({
      project_path = fs.join_paths(session_path, provider.file),
      global_path = fs.join_paths(config.options.root_dir, provider.file),
    })
  end
end

---@param session_path string
function M.save(session_path)
  for _, provider in ipairs(session_providers) do
    provider.save({
      project_path = fs.join_paths(session_path, provider.file),
      global_path = fs.join_paths(config.options.root_dir, provider.file),
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
  local scan = vim.fn.globpath(config.options.root_dir, "*", 0, 1)
  local sessions = {}

  for _, entry in ipairs(scan) do
    if vim.fn.isdirectory(entry) ~= 0 then
      local dir_name = vim.fn.fnamemodify(entry, ":t") -- Get directory name
      local decoded_name = M.decode_name(dir_name)

      table.insert(sessions, {
        base = decoded_name.project,
        branch = decoded_name.branch,
        name = dir_name,
        path = entry,
      })
    end
  end

  return sessions
end

---@param name string
function M.decode_name(name)
  local split_parts = utils.split(name, consts.SPECIAL_SEPARATOR)

  return {
    project = encoding.decode(split_parts[1]),
    branch = split_parts[2] and utils.decode(split_parts[2]) or nil,
  }
end

---@param opts { use_git_host?: boolean; use_git_branch?: boolean;  }
---@param force_git_branch? string
function M.get_name(opts, force_git_branch)
  local parts = {}
  local used_git_host = false

  if opts.use_git_host then
    local git_host = git.repo_host()
    if not git_host then
      logger.warn("Cannot read git host in this repo, fallbacking to cwd")
    else
      table.insert(parts, encoding.encode(git_host))
      used_git_host = true
    end
  end

  if not used_git_host then
    local root_path = git.repo_path() or vim.fn.getcwd()
    table.insert(parts, encoding.encode(root_path))
  end

  if opts.use_git_branch then
    local git_branch = force_git_branch or git.repo_branch()
    if not git_branch then
      logger.warn("Cannot detect git branch")
    else
      table.insert(parts, encoding.encode(git_branch))
    end
  end
  local name = table.concat(parts, consts.SPECIAL_SEPARATOR)

  return name
end

return M
