local utils = require("continue.utils")
local system = require("continue.utils.system")
local logger = require("continue.logger.logger")
local fs = require("continue.utils.fs")
local M = {}

---@return string|nil
function M.repo_path()
  local git_dir = vim.trim(vim.fn.system("git rev-parse --path-format=absolute --git-dir"))

  if vim.v.shell_error ~= 0 or git_dir == "" then
    logger.debug("Failed to get Git directory.  Error code: %d", vim.v.shell_error)
    return nil
  end

  git_dir = git_dir:gsub("[\n\r]", "")

  local git_root = git_dir:gsub("/worktrees/.*", "")

  local is_inside_git_folder = git_root:match("/%.git$")
  if is_inside_git_folder then
    return vim.fs.dirname(git_root)
  end

  return git_root
end

function M.is_git_repo(cb)
  system.call_shell_cb({ "git", "rev-parse", "--is-inside-work-tree" }, cb)
end

function M.get_git_project_root()
  local project_dir = vim.trim(vim.fn.system("git rev-parse --show-toplevel"))

  if vim.v.shell_error ~= 0 or project_dir == "" then
    logger.debug("Failed to get git project directory.  Error code: %d", vim.v.shell_error)
    return nil
  end

  return project_dir
end

---@param remote_name string
---@return string|nil
function M.repo_host(remote_name)
  local url = vim.trim(vim.fn.system(string.format("git config --get remote.%s.url", remote_name)))
  if not url or url == "" or string.match(url, "^fatal:") then
    return nil
  end

  return M.format_repo_host(url)
end

function M.repo_branch()
  local branch_name = vim.trim(vim.fn.system("git branch --show-current"))
  if not branch_name or branch_name == "" or string.match(branch_name, "fatal:") then
    return nil
  end

  return branch_name
end

---@param url string
function M.format_repo_host(url)
  local normalized_url = url:gsub("%s+$", "")

  local remove_git_extension = function(input)
    return input:gsub("%.git$", "")
  end

  local ssh_path = normalized_url:match("^git@[^:]+:(.+)")
  if ssh_path then
    return remove_git_extension(ssh_path)
  end

  local https_path = normalized_url:match("^https?://[^/]+/(.+)")
  if https_path then
    return remove_git_extension(https_path)
  end
end

---@param cb function
function M.watch_branch_changes(cb)
  local watcher = utils.is_windows() and vim.uv.new_fs_poll() or vim.uv.new_fs_event()
  local git_dir = vim.trim(vim.fn.system("git rev-parse --path-format=absolute --git-dir"))
  local git_head = fs.join_paths(git_dir, "HEAD")

  local function read_head_branch()
    local f_head = io.open(git_head)
    if f_head then
      local HEAD = f_head:read()
      f_head:close()
      local branch = HEAD:match("ref: refs/heads/(.+)$")
      if branch then
        return branch
      else
        return HEAD:sub(1, 6)
      end
    end
    return nil
  end
  local current_branch = read_head_branch()

  if current_branch == nil then
    logger.debug("Cannot find a head file in the git repository %s", vim.fn.getcwd())
    return
  end

  local function watch()
    local head_branch = read_head_branch()
    watcher:stop()
    if head_branch ~= current_branch then
      logger.debug("Detected branch change from %s to %s", current_branch, head_branch)
      cb(current_branch)
      current_branch = head_branch
    end

    watcher:start(
      git_head,
      utils.is_windows() and 1000 or {},
      vim.schedule_wrap(function()
        watch()
      end)
    )
  end

  watch()
end

return M
