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
  local saved_windows = {}
  local wins = vim.api.nvim_list_wins()

  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype

    if ft == "trouble" then
      local win_config = vim.api.nvim_win_get_config(win)
      local win_info = {
        config = win_config,
        row = win_config.row,
        col = win_config.col,
        width = vim.api.nvim_win_get_width(win),
        height = vim.api.nvim_win_get_height(win),
        lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false),
        cursor = vim.api.nvim_win_get_cursor(win),
        options = {
          wrap = vim.wo[win].wrap,
          foldmethod = vim.wo[win].foldmethod,
          foldlevel = vim.wo[win].foldlevel,
        },
        buf_options = {
          filetype = ft,
          buftype = vim.bo[buf].buftype,
        },
      }
      table.insert(saved_windows, win_info)
    end
  end

  return saved_windows
end

function M.load(data)
  for _, win_info in ipairs(data) do
    local buf = vim.api.nvim_create_buf(false, true)

    vim.bo[buf].filetype = win_info.buf_options.filetype
    vim.bo[buf].buftype = win_info.buf_options.buftype

    local win_config = win_info.config
    win_config.buf = nil
    local win = vim.api.nvim_open_win(buf, false, win_config)

    vim.wo[win].wrap = win_info.options.wrap
    vim.wo[win].foldmethod = win_info.options.foldmethod
    vim.wo[win].foldlevel = win_info.options.foldlevel

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, win_info.lines)
    vim.api.nvim_win_set_cursor(win, win_info.cursor)
  end
end

return M
