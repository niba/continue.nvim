local generator = require("tests_helpers.generator")
local Helpers = {}

local root_dir = vim.fn.fnamemodify("tests/.sessions", ":p")
---@type Continue.Config
local test_default_opts = {
  root_dir = root_dir,
  auto_restore_on_branch_change = false,
  auto_save = false,
  auto_restore = false,
  react_on_cwd_change = false,
  custom_builtin = {
    codecompanion = false,
    qf = false,
  },
}

Helpers.root_dir = root_dir

Helpers.projects = {
  basic = "tests/projects/basic",
  basic2 = "tests/projects/basic2",
  git = "tests/projects/git",
}
Helpers.expect = vim.deepcopy(MiniTest.expect)

Helpers.expect.match = MiniTest.new_expectation("string matching", function(str, pattern)
  return str:find(pattern) ~= nil
end, function(str, pattern)
  return string.format("Pattern: %s\nObserved string: %s", vim.inspect(pattern), str)
end)

Helpers.expect.no_match = MiniTest.new_expectation("no string matching", function(str, pattern)
  return str:find(pattern) == nil
end, function(str, pattern)
  return string.format("Pattern: %s\nObserved string: %s", vim.inspect(pattern), str)
end)

Helpers.expect.equality_approx = MiniTest.new_expectation(
  "approximate equality",
  function(x, y, tol)
    if type(x) ~= type(y) then
      return false
    end
    if type(x) == "number" then
      return math.abs(x - y) <= tol
    end
    if type(x) ~= "table" then
      return vim.deep_equal(x, y)
    end

    local x_keys, y_keys = vim.tbl_keys(x), vim.tbl_keys(y)
    table.sort(x_keys)
    table.sort(y_keys)
    if not vim.deep_equal(x_keys, y_keys) then
      return false
    end
    for _, key in ipairs(x_keys) do
      if math.abs(x[key] - y[key]) > tol then
        return false
      end
    end

    return true
  end,
  function(x, y, tol)
    return string.format("Left: %s\nRight: %s\nTolerance: %s", vim.inspect(x), vim.inspect(y), tol)
  end
)

Helpers.make_partial_tbl = function(tbl, ref)
  local res = {}
  for k, v in pairs(ref) do
    res[k] = (type(tbl[k]) == "table" and type(v) == "table")
        and Helpers.make_partial_tbl(tbl[k], v)
      or tbl[k]
  end
  for i = 1, #tbl do
    if ref[i] == nil then
      res[i] = tbl[i]
    end
  end
  return res
end

Helpers.expect.equality_partial_tbl = MiniTest.new_expectation(
  "equality of tables only in reference fields",
  function(x, y)
    if type(x) == "table" and type(y) == "table" then
      x = Helpers.make_partial_tbl(x, y, {})
    end
    return vim.deep_equal(x, y)
  end,
  function(x, y)
    return string.format(
      "Left: %s\nRight: %s",
      vim.inspect(Helpers.make_partial_tbl(x, y, {})),
      vim.inspect(y)
    )
  end
)

---@param plugin_opts Continue.Config
---@param cwd? string
Helpers.new_child_neovim = function(plugin_opts, cwd)
  local child = MiniTest.new_child_neovim()
  local args = { "-u", "tests/minit_generated.lua" }

  local manager = {
    ---@param extra_args? table<string>
    start = function(extra_args)
      generator.generate_config(vim.tbl_deep_extend("force", test_default_opts, plugin_opts), cwd)
      local start_args = vim.deepcopy(args)
      if extra_args then
        for _, v in ipairs(extra_args) do
          table.insert(start_args, v)
        end
      end
      child.start(start_args)
    end,
    stop = function()
      child.stop()
    end,
    ---@param new_plugin_opts? Continue.Config
    ---@param extra_args? table<string>
    restart = function(new_plugin_opts, extra_args)
      local start_args = vim.deepcopy(args)
      generator.generate_config(
        vim.tbl_deep_extend("force", test_default_opts, plugin_opts, new_plugin_opts or {}),
        cwd
      )
      if extra_args then
        for _, v in ipairs(extra_args) do
          table.insert(start_args, v)
        end
      end
      child.restart(start_args)
    end,
    ---@param new_plugin_opts Continue.Config
    reload_plugin = function(new_plugin_opts)
      return child.lua_func(function(new_opts)
        require("lazy.core.config").plugins["continue"].opts = new_opts
        require("lazy").reload({ plugins = { "continue" } })
      end, vim.tbl_deep_extend("force", test_default_opts, plugin_opts, new_plugin_opts))
    end,
  }

  return child, manager
end

Helpers.clean_sessions_data = function()
  local sessions_dir = vim.fn.fnamemodify(root_dir, ":p")

  vim.fn.delete(sessions_dir, "rf")
end

Helpers.get_existing_sessions_dirs = function()
  local dirs = {}
  local iter, err = vim.fs.dir(root_dir)
  if not iter then
    print("Error reading directory: " .. (err or "unknown error"))
    return dirs
  end

  for name, type in iter do
    if type == "directory" then
      table.insert(dirs, name)
    end
  end
  return dirs
end

return Helpers
