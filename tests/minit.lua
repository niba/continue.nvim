#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"
vim.env.LAZY_PATH = vim.fs.normalize("~/Documents/Projects/neovim/lazy.nvim")
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Setup lazy.nvim
require("lazy.minit").setup({
  spec = {
    "nvim-lua/plenary.nvim",
    {
      dir = vim.uv.cwd(),
      opts = {},
    },
  },
})
