local logger = require("continuum.logger.logger")
---@class Continuum.CustomHandler
local M = {}

M.id = "quickfix"

local function is_quickfix_open()
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      return true
    end
  end
  return false
end

function M.save()
  if not is_quickfix_open() then
    return nil
  end

  local qf_list = vim.fn.getqflist()
  local qf_info = vim.fn.getqflist({ nr = 0, title = 0, winid = 0 })

  local serializable_list = {
    items = {},
    title = qf_info.title,
    nr = qf_info.nr,
    height = vim.api.nvim_win_get_height(qf_info.winid),
    position = vim.fn.win_screenpos(qf_info.winid)[1],
  }

  for _, item in ipairs(qf_list) do
    local filename = vim.fn.bufname(item.bufnr)
    table.insert(serializable_list.items, {
      filename = filename,
      lnum = item.lnum,
      col = item.col,
      text = item.text,
      type = item.type,
    })
  end

  return serializable_list
end

function M.load(data)
  if not data then
    logger.info("No quickfix data")
    return false
  end

  if not data.items then
    logger.info("No quickfix data")
    return false
  end

  local qf_items = {}
  for _, item in ipairs(data.items) do
    local bufnr = vim.fn.bufnr(item.filename, true)
    table.insert(qf_items, {
      bufnr = bufnr,
      lnum = item.lnum,
      col = item.col,
      text = item.text,
      type = item.type,
    })
  end

  vim.fn.setqflist(qf_items, "r")
  vim.fn.setqflist({}, "r", {
    title = data.title,
    nr = data.nr or 0,
  })

  if not is_quickfix_open() then
    local current_win = vim.api.nvim_get_current_win()
    vim.cmd("copen")

    if data.height then
      vim.cmd(string.format("resize %d", data.height))
    end
    vim.api.nvim_set_current_win(current_win)
  end
end

return M
