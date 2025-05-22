local MiniTest = require("mini.test")
local h = require("tests_helpers.helpers")

local child, manager = h.new_child_neovim({
  auto_restore = false,
  auto_save = false,
  auto_restore_on_branch_change = false,
}, h.projects.basic)

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      h.clean_sessions_data()
      manager.restart()
    end,
  },
})

T["should load with minimal config"] = function()
  local plugin_loaded = child.lua_func(function()
    return type(require("continue")) == "table"
  end)

  MiniTest.expect.equality(plugin_loaded, true)
end

T["should not create sessions data with auto_save = false"] = function()
  manager.stop()

  local dirs = h.get_existing_sessions_dirs()

  MiniTest.expect.equality(dirs, {})
end

T["should create sessions data with auto_save = true"] = function()
  manager.restart({
    auto_save = true,
    auto_save_min_buffer = 0,
  })
  manager.stop()

  local dirs = h.get_existing_sessions_dirs()

  MiniTest.expect.equality(#dirs, 1)
end

T["should respect min buffer when auto save"] = function()
  manager.restart({
    auto_save = true,
    auto_save_min_buffer = 1,
  })
  manager.stop()

  local dirs = h.get_existing_sessions_dirs()

  MiniTest.expect.equality(#dirs, 0)
end

T["should create sessions data"] = function()
  child.lua_func(function()
    require("continue").save()
  end)

  local dirs = h.get_existing_sessions_dirs()
  MiniTest.expect.equality(#dirs, 1)
end

T["should delete sessions data"] = function()
  child.lua_func(function()
    require("continue").save()
    vim.schedule(function()
      vim.fn.feedkeys("y" .. vim.api.nvim_replace_termcodes("<CR>", true, false, true), "t")
    end)
    require("continue").delete()
  end)

  local dirs = h.get_existing_sessions_dirs()
  MiniTest.expect.equality(#dirs, 0)
end

T["should create sessions data with custom name"] = function()
  child.lua_func(function()
    require("continue").save("test_name")
  end)

  local dirs = h.get_existing_sessions_dirs()
  MiniTest.expect.equality(#dirs, 1)
  MiniTest.expect.equality(dirs, { "test_name" })
end

T["should detect pager mode"] = function()
  manager.stop()
  manager.start({ "tests/projects/basic/file.txt" })

  local pager_mode = child.lua_func(function()
    return require("continue.consts").get_pager_mode()
  end)

  MiniTest.expect.equality(pager_mode, true)
end

T["should load sessions data"] = function()
  -- do nothing when no session
  child.lua_func(function()
    require("continue").load()
  end)

  local buffer_name = child.lua_func(function()
    vim.cmd("edit file.txt")
    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename
  end)

  MiniTest.expect.equality(buffer_name, "file.txt")

  buffer_name = child.lua_func(function()
    require("continue").save()
    vim.cmd("bufdo bdelete!")
    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename
  end)

  MiniTest.expect.equality(buffer_name, "")

  buffer_name = child.lua_func(function()
    require("continue").load()
    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename
  end)

  MiniTest.expect.equality(buffer_name, "file.txt")
end

T["should auto restore sessions"] = function()
  local buffer_name = child.lua_func(function()
    vim.cmd("edit file.txt")
    require("continue").save()
    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename
  end)

  MiniTest.expect.equality(buffer_name, "file.txt")

  manager.restart({
    auto_restore = true,
  })

  -- give time to restore
  vim.loop.sleep(1000)
  buffer_name = child.lua_func(function()
    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename
  end)

  MiniTest.expect.equality(buffer_name, "file.txt")
end

return T
