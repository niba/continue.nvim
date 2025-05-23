local consts = require("continue.consts")
local logger = require("continue.logger.logger")
local utils = require("continue.utils.init")
local ecosystem = require("continue.utils.ecosystem")

local M = {}

local augroup = vim.api.nvim_create_augroup("continue", { clear = true })

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
---@param callbacks Continue.OnCwdChange
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

local get_dir_arg = function()
  local vim_arg = vim.fn.argv(0)

  if not vim_arg or #vim_arg == 0 then
    return nil
  end

  local uv = (vim.uv or vim.loop)
  local stats = uv.fs_stat(vim_arg)
  if not stats or stats.type ~= "directory" then
    return nil
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  if not utils.truthy(bufname) then
    bufname = vim_arg or ""
  end
  local stats = uv.fs_stat(bufname)
  if not stats then
    return nil
  end
  if stats.type ~= "directory" then
    return nil
  end

  return bufname
end

---@param fn fun(dir_path?: string): nil
function M.on_start(fn)
  local defer_fn = function()
    vim.schedule(function()
      fn(get_dir_arg())
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

---Fire an event
---@param event string
---@param opts? table
function M.fire(event, opts)
  opts = opts or {}
  vim.api.nvim_exec_autocmds("User", { pattern = consts.PLUGIN_NAME .. event, data = opts })
end

return M
