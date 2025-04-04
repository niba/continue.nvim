return {
  {
    "folke/lazydev.nvim",
    opts = function(_, opts)
      -- add lsp support for helpers files in tests
      table.insert(opts.library, "tests")
      return opts
    end,
  },
}
