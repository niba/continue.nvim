local git = require("continue.utils.git")
local encoding = require("continue.utils.encoding")
local MiniTest = require("mini.test")
local h = require("tests_helpers.helpers")

local git_project = vim.fn.fnamemodify(h.projects.git, ":p")

local call_cmd = function(cmd, allow_fail)
  local output = vim.system(cmd, { cwd = git_project }):wait()

  local success = output.code == 0

  if allow_fail then
    return success
  end

  if not success then
    error(string.format("Error running cmd: %s", output.stderr))
  end
end

local child, manager = h.new_child_neovim({
  auto_restore = false,
  auto_save = false,
  auto_restore_on_branch_change = false,
  use_git_branch = true,
  use_git_host = true,
}, h.projects.git)

local git_dir = "tests/projects/git/.git"
local git_renamed_dir = "tests/projects/git/.git_dir"

local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      vim.fn.rename(git_renamed_dir, git_dir)
    end,
    pre_case = function()
      h.clean_sessions_data()
    end,
    post_once = function()
      vim.fn.rename(git_dir, git_renamed_dir)
    end,
  },
})

T["can parse git host"] = function()
  MiniTest.expect.equality(git.format_repo_host("aaa"), nil)
  MiniTest.expect.equality(
    git.format_repo_host("git@github.com:Test-org/ProjectName.git"),
    "Test-org/ProjectName"
  )
  MiniTest.expect.equality(
    git.format_repo_host("https://github.com/Test-org/ProjectName.nvim.git"),
    "Test-org/ProjectName.nvim"
  )
end

T["generate session name using git data"] = function()
  call_cmd({ "git", "checkout", "main" })
  call_cmd({ "git", "remote", "remove", "test" }, true)
  manager.start()

  local session_name = child.lua_func(function()
    local config = require("continue.config")
    return require("continue.sessions").get_name(config.options)
  end)

  -- use git branch in session name
  -- use path in session name
  h.expect.match(
    session_name,
    string.format("%s__%s$", encoding.encode("tests/projects/git"), "main")
  )

  manager.restart({
    use_git_host = true,
    use_git_branch = false,
    git_remote = "test",
  })

  session_name = child.lua_func(function()
    local config = require("continue.config")
    return require("continue.sessions").get_name(config.options)
  end)

  -- don't use git branch in session name
  h.expect.match(session_name, string.format("%s$", encoding.encode("tests/projects/git")))

  call_cmd({ "git", "remote", "add", "test", "https://github.com/niba/test-repo.git" })

  session_name = child.lua_func(function()
    local config = require("continue.config")
    return require("continue.sessions").get_name(config.options)
  end)

  -- use remote in name
  h.expect.equality(session_name, string.format("%s", encoding.encode("niba/test-repo")))

  manager.restart({
    use_git_host = false,
    use_git_branch = false,
    git_remote = "test",
  })

  session_name = child.lua_func(function()
    local config = require("continue.config")
    return require("continue.sessions").get_name(config.options)
  end)

  -- dont use remote in name
  h.expect.match(session_name, string.format("%s", encoding.encode("tests/projects/git")))
  call_cmd({ "git", "remote", "remove", "test" })
  manager.stop()
end

T["should change session when change branch"] = function()
  call_cmd({ "git", "checkout", "main" })
  call_cmd({ "git", "remote", "remove", "test" }, true)
  manager.restart({
    use_git_branch = true,
  })
  child.lua_func(function()
    vim.cmd("edit file.txt")
    require("continue").save()
  end)
  manager.stop()

  call_cmd({ "git", "checkout", "test" })
  manager.restart({
    use_git_branch = true,
  })
  child.lua_func(function()
    vim.cmd("edit testfile.txt")
    require("continue").save()
  end)
  manager.stop()

  call_cmd({ "git", "checkout", "main" })
  manager.restart({
    use_git_branch = true,
    auto_restore_on_branch_change = true,
  })
  -- give time to start watcher
  vim.loop.sleep(500)

  local buffer_name = child.lua_func(function()
    require("continue").load()
    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename
  end)
  MiniTest.expect.equality(buffer_name, "file.txt")

  call_cmd({ "git", "checkout", "test" })
  vim.loop.sleep(100)
  buffer_name = child.lua_func(function()
    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename
  end)
  MiniTest.expect.equality(buffer_name, "testfile.txt")
  manager.stop()
end

return T
