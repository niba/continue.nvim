local git = require("continue.utils.git")
local utils = require("continue.utils")
local config = require("continue.config")
local encoding = require("continue.utils.encoding")
local logger = require("continue.logger.logger")
local fs = require("continue.utils.fs")
local consts = require("continue.consts")
local mks = require("continue.sessions.mks")
local shada = require("continue.sessions.shada")
local extensions = require("continue.sessions.extensions")

local session_providers = {
  mks,
  shada,
  extensions,
}

local M = {}

---@param session_path string
function M.load(session_path)
  local project_root = M.get_project_root(config.options)

  if config.options.hooks and config.options.hooks.pre_restore then
    pcall(function()
      config.options.hooks.pre_restore({
        project_path = project_root,
        cwd_path = vim.uv.cwd(),
      })
    end)
  end

  vim.cmd([[silent! tabonly!]])
  vim.cmd([[silent! %bd!]])
  vim.cmd([[silent! %bw!]])

  for _, provider in ipairs(session_providers) do
    pcall(function()
      provider.load({
        project_data_path = fs.join_paths(session_path, provider.file),
        global_data_path = fs.join_paths(config.options.root_dir, provider.file),
        project_root = project_root,
      })
    end)
  end

  pcall(function()
    config.options.hooks.post_restore({
      project_path = project_root,
      cwd_path = vim.uv.cwd(),
    })
  end)
end

---@param session_path string
function M.save(session_path)
  local project_root = M.get_project_root(config.options)

  if config.options.hooks and config.options.hooks.pre_save then
    pcall(function()
      config.options.hooks.pre_save({
        project_path = project_root,
        cwd_path = vim.uv.cwd(),
      })
    end)
  end

  for _, provider in ipairs(session_providers) do
    pcall(function()
      provider.save({
        project_data_path = fs.join_paths(session_path, provider.file),
        global_data_path = fs.join_paths(config.options.root_dir, provider.file),
        project_root = project_root,
      })
    end)
  end

  if config.options.hooks and config.options.hooks.post_save then
    pcall(function()
      config.options.hooks.post_save({
        project_path = project_root,
        cwd_path = vim.uv.cwd(),
      })
    end)
  end
end

---@param opts Continue.Config
function M.init(opts)
  for _, provider in ipairs(session_providers) do
    if type(provider.init) == "function" then
      pcall(function()
        provider.init(opts)
      end)
    end
  end
end

---@param path string
function M.delete(path, name)
  logger.debug("Deleting session with path %s", path)

  local data_dir = config.options.root_dir
  local normalized_path = vim.fs.normalize(path)
  local normalized_data_dir = vim.fs.normalize(data_dir)

  if not string.find(normalized_path, normalized_data_dir, 1, true) then
    logger.error(
      "Error while removing session [%s] - sessions data is located outside of plugin data_dir (%s)",
      name,
      path
    )
    return false
  end

  local success, error = fs.remove_dir(path, "Remove session?")

  if not success then
    logger.error("Error while removing session [%s] with path (%s): %s", name, path, error)
    return false
  end

  logger.debug("Session [%s] has been deleted", name)
  return true
end

---@param opts? { all?: boolean }
---@return Continue.PickerData[]
function M.list(opts)
  local scan = vim.fn.globpath(config.options.root_dir, "*", 0, 1)
  local sessions = {}

  local pattern = opts and opts.all and "" or M.get_base_name(config.options)

  logger.info("Used pattern %s", pattern)

  for _, entry in ipairs(scan) do
    if vim.fn.isdirectory(entry) ~= 0 then
      local dir_name = vim.fn.fnamemodify(entry, ":t") -- Get directory name
      local decoded_name = M.decode_name(dir_name)

      if string.sub(decoded_name.project, 1, #pattern) == pattern then
        table.insert(sessions, {
          base = decoded_name.project,
          branch = decoded_name.branch,
          name = dir_name,
          path = entry,
        })
      end
    end
  end

  return sessions
end

---@param name string
function M.decode_name(name)
  local split_parts = utils.split(name, consts.SPECIAL_SEPARATOR)

  return {
    project = encoding.decode(split_parts[1]),
    branch = split_parts[2] and encoding.decode(split_parts[2]) or nil,
  }
end

---@param data Continue.PickerData
---@return string
function M.display(data)
  if data.branch then
    return string.format("%s [%s]", data.base, data.branch)
  end
  return data.base
end

local function get_remote()
  if type(config.options.git_remote) ~= "string" then
    config.options.git_remote(vim.uv.cwd())
  end
  return config.options.git_remote
end

---@param opts { use_git_host?: boolean }
---@return string
function M.get_base_name(opts)
  if opts.use_git_host then
    local git_host = git.repo_host(get_remote())
    if not git_host then
      logger.warn("Cannot read git host in this repo, fallbacking to cwd")
    else
      return git_host
    end
  end

  local root_path = git.repo_path() or vim.uv.cwd()
  return root_path
end

---@param opts { use_git_host?: boolean; use_git_branch?: boolean;  }
---@param force_git_branch? string
function M.get_name(opts, force_git_branch)
  local parts = {}

  local base_name = M.get_base_name(opts)
  table.insert(parts, encoding.encode(base_name))

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

---@param opts { use_git_host?: boolean; }
function M.get_project_root(opts)
  if opts.use_git_host then
    return git.get_git_project_root() or vim.uv.cwd()
  end

  return vim.uv.cwd()
end

return M
