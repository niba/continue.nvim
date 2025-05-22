#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = vim.fn.fnamemodify(".tests", ":p")
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

local plugin_dir = vim.uv.cwd()
vim.cmd("cd tests/projects/basic")
-- Setup lazy.nvim
require("lazy.minit").setup({
  spec = {
    "nvim-lua/plenary.nvim",
    {
      dir = plugin_dir,
      name = "continue",
      lazy = false,
      config = true,
      opts = {
  auto_restore = false,
  auto_restore_on_branch_change = false,
  auto_save = false,
  custom_builtin = {
    codecompanion = false,
    qf = false
  },
  react_on_cwd_change = false,
  root_dir = "/Users/niba/Documents/Projects/neovim/continue/tests/.sessions/"
},
    },
  },
})
