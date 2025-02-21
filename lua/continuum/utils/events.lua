local consts = require("continuum.consts")
local logger = require("continuum.logger.logger")
local ecosystem = require("continuum.utils.ecosystem")

local M = {}

local augroup = vim.api.nvim_create_augroup("continuum", { clear = true })

function M.register_commands()
  vim.api.nvim_create_autocmd({ "StdinReadPre" }, {
    group = augroup,
    pattern = "*",
    callback = function()
      logger.debug("Detected pager mode, stopping auto save")
      consts.enable_pager_mode()
    end,
  })
end

function M.on_start(fn)
  if ecosystem.has_lazy_manager() then
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyDone",
      callback = function()
        fn()
      end,
      group = augroup,
      once = true,
    })
    return
  end

  vim.api.nvim_create_autocmd({ "VimEnter" }, {
    pattern = "*",
    callback = function()
      fn()
    end,
    group = augroup,
    once = true,
  })
end

function M.on_end(fn)
  vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
    pattern = "*",
    callback = function()
      fn()
    end,
    group = augroup,
    once = true,
  })
end

return M
