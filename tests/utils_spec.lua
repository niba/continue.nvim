local MiniTest = require("mini.test")
local h = require("tests_helpers.helpers")
local encoding = require("continuum.utils.encoding")
local utils = require("continuum.utils")

local T = MiniTest.new_set()

local child, manager = h.new_child_neovim({
  auto_restore = false,
  auto_save = false,
  auto_restore_on_branch_change = false,
}, h.projects.basic)

T["should encode text"] = function()
  MiniTest.expect.equality(encoding.encode("org/project_name"), "org_2Fproject_name")
end

T["should decode text"] = function()
  MiniTest.expect.equality(encoding.decode("org_2Fproject_name"), "org/project_name")
end

T["should split text"] = function()
  MiniTest.expect.equality(utils.split("test_ada", "_"), { "test", "ada" })
end

T["should perform shallow merge"] = function()
  MiniTest.expect.equality(
    utils.merge({
      a = 6,
      b = 3,
    }, {
      a = 1,
      c = 3,
    }),
    {
      a = 1,
      b = 3,
      c = 3,
    }
  )
end

T["should perform shallow merge and handle nil values"] = function()
  MiniTest.expect.equality(
    utils.merge({
      a = 6,
      b = 3,
    }, {
      a = nil,
      b = 1,
      c = 3,
    }),
    {
      a = 6,
      b = 1,
      c = 3,
    }
  )
end

T["should return buffer count"] = function()
  manager.start()

  local buffer_count = child.lua_func(function()
    vim.cmd("edit file.txt")
    vim.cmd("edit file2.txt")

    return require("continuum.utils").buffers_count()
  end)

  MiniTest.expect.equality(buffer_count, 2)

  manager.stop()
end

T["should detect file argument"] = function()
  manager.start({ "tests/projects/basic/file.txt" })

  local file_argument = child.lua_func(function()
    return require("continuum.utils").has_file_as_argument()
  end)

  MiniTest.expect.equality(file_argument, true)

  manager.restart()

  file_argument = child.lua_func(function()
    return require("continuum.utils").has_file_as_argument()
  end)

  MiniTest.expect.equality(file_argument, false)

  manager.stop()
end

return T
