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

T["should handle save and load commands"] = function()
  child.lua_func(function()
    vim.cmd("edit file.txt")
    vim.cmd("ContinueSave")
  end)

  manager.restart()
  local buffer_name = child.lua_func(function()
    vim.cmd("ContinueLoad")
    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename
  end)

  MiniTest.expect.equality(buffer_name, "file.txt")
end

T["should handle remove commands"] = function()
  child.lua_func(function()
    vim.cmd("edit file.txt")
    vim.cmd("ContinueSave")
  end)

  local dirs = h.get_existing_sessions_dirs()
  MiniTest.expect.equality(#dirs, 1)

  child.lua_func(function()
    vim.cmd("edit file.txt")
    vim.schedule(function()
      vim.fn.feedkeys("y" .. vim.api.nvim_replace_termcodes("<CR>", true, false, true), "t")
    end)
    vim.cmd("ContinueDelete")
  end)

  dirs = h.get_existing_sessions_dirs()
  MiniTest.expect.equality(#dirs, 0)
end

T["should toggle auto save functionality"] = function()
  manager.restart({ auto_save = true })
  child.lua_func(function()
    vim.cmd("edit file.txt")
  end)

  manager.restart({ auto_save = true })

  local buffer_name = child.lua_func(function()
    vim.cmd("ContinueLoad")

    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    vim.cmd("ContinueToggleAutoSave")
    vim.cmd("edit file2.txt")
    return filename
  end)
  MiniTest.expect.equality(buffer_name, "file.txt")

  manager.restart({ auto_save = true })

  buffer_name = child.lua_func(function()
    vim.cmd("ContinueLoad")
    local current_buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(current_buf)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename
  end)

  MiniTest.expect.equality(buffer_name, "file.txt")
end

return T
