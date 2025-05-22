vim.env.LAZY_STDPATH = ".repro_telescope"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

local plugins = {
  {
    "stevearc/oil.nvim",
  },
  {
    "continue",
    dev = true,
    dependencies = {
      { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
    },
    opts = {
      opts = {
        log_level = "DEBUG",
      },
    },
  },
}

require("lazy.minit").repro({
  spec = plugins,
  dev = {
    path = "~/Documents/Projects/neovim",
  },
})
