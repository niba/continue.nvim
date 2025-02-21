local git = require("continuum.utils.git")
local utils = require("continuum.utils")
local config = require("continuum.config")
local encoding = require("continuum.utils.encoding")
local logger = require("continuum.logger.logger")
local fs = require("continuum.utils.fs")
local consts = require("continuum.consts")
local mks = require("continuum.sessions.mks")
local shada = require("continuum.sessions.shada")
local custom = require("continuum.sessions.custom")
local picker = require("continuum.pickers.picker")

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

---@param opts Continuum.Config
function M.init(opts)
  for _, provider in ipairs(session_providers) do
    if type(provider.init) == "function" then
      provider.init(opts)
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
---@return Continuum.PickerData[]
function M.list(opts)
  local scan = vim.fn.globpath(config.options.root_dir, "*", 0, 1)
  local sessions = {}

  local pattern = opts and opts.all and "" or M.get_base_name(config.options)

  logger.info("Used pattern %s", pattern)

  for _, entry in ipairs(scan) do
    if vim.fn.isdirectory(entry) ~= 0 then
      local dir_name = vim.fn.fnamemodify(entry, ":t") -- Get directory name
      local decoded_name = M.decode_name(dir_name)

      logger.info("pattern %s follow project name: %s", pattern, decoded_name.project)

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

---@param data Continuum.PickerData
---@return string
function M.display(data)
  if data.branch then
    return string.format("%s [%s]", data.base, data.branch)
  end
  return data.base
end

---@param opts { use_git_host?: boolean }
---@return string
function M.get_base_name(opts)
  if opts.use_git_host then
    local git_host = git.repo_host()
    if not git_host then
      logger.warn("Cannot read git host in this repo, fallbacking to cwd")
    else
      return git_host
    end
  end

  local root_path = git.repo_path() or vim.fn.getcwd()
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

---@param opts? Continuum.SearchOpts
function M.search(opts)
  picker.pick({
    title = consts.PICKER_TITLE,
    preview = false,
    get_data = function()
      local data = M.list(opts)

      return vim
        .iter(data)
        :map(function(session)
          return {
            text = M.display(session),
            value = session,
            path = session.path,
          }
        end)
        :totable()
    end,
    actions = {
      confirm = {
        handler = function(item)
          M.load(item.path)
        end,
      },
      delete = {
        handler = function(item)
          M.delete(item.path, item.value.name)
        end,
        mode = config.options.mappings.delete_session[1],
        key = config.options.mappings.delete_session[2],
      },
    },
  }, opts and opts.picker or nil)
end

return M
