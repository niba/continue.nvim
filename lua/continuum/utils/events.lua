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

local CWD_LOCK = false
---@param callbacks Continuum.OnCwdChange
function M.on_cwd_change(callbacks)
  vim.api.nvim_create_autocmd("DirChangedPre", {
    pattern = "global",
    callback = function()
      if vim.v.event.changed_window then
        return
      end

      if vim.v.event.scope ~= "global" then
        return
      end

      if CWD_LOCK then
        return
      end

      if not callbacks.condition() then
        return
      end

      logger.debug(
        "Detected cwd change from %s to %s with scope %s and window %s",
        vim.fn.getcwd(-1, -1),
        vim.v.event.directory,
        vim.v.event.scope,
        vim.v.event.changed_window
      )

      CWD_LOCK = true
      pcall(callbacks.before_change)

      -- TODO: vim.api.nvim_create_autocmd("DirChanged", {
      vim.schedule(function()
        pcall(callbacks.after_change)
        CWD_LOCK = false
      end)
    end,
  })
end

function M.on_start(fn)
  local defer_fn = function()
    vim.schedule(function()
      fn()
    end)
  end

  if ecosystem.has_lazy_manager() then
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyDone",
      callback = function()
        local lazy_view = require("lazy.view")
        if not lazy_view.visible() then
          defer_fn()
          return
        end
        local lazy_view_id = lazy_view.view.win
        M.win_close_autocmd = vim.api.nvim_create_autocmd("WinClosed", {
          group = augroup,
          callback = function(args)
            if lazy_view_id == tonumber(args.match) then
              vim.api.nvim_del_autocmd(M.win_close_autocmd)
              defer_fn()
            end
          end,
        })
      end,
      group = augroup,
      once = true,
    })
    return
  end

  vim.api.nvim_create_autocmd({ "VimEnter" }, {
    pattern = "*",
    callback = function()
      defer_fn()
    end,
    group = augroup,
    once = true,
  })
end

function M.on_end(fn)
  local group_id = vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
    pattern = "*",
    callback = function()
      fn()
    end,
    group = augroup,
    once = true,
  })

  return function()
    pcall(vim.api.nvim_del_autocmd, group_id)
  end
end

return M
