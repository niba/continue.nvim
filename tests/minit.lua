#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Setup lazy.nvim
require("lazy.minit").setup({
  spec = {
    "nvim-lua/plenary.nvim",
    {
      dir = vim.uv.cwd(),
      ---@type Continue.Config
      opts = {
        auto_restore = false,
        auto_save = false,
        use_git_branch = false,
        root_dir = "tests/.sessions",
      },
    },
  },
})
