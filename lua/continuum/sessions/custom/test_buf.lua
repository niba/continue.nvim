local logger = require("continuum.logger.logger")
-- local target_bufnr = 8
-- local original_bufnr = 3 --vim.api.nvim_get_current_buf()
--
-- -- Use Vimscript's :noautocmd with buffer switching
-- vim.cmd(string.format("noautocmd keepalt keepjumps silent buffer %d | buffer %d", target_bufnr, original_bufnr))

---@class Continuum.CustomHandler
local M = {}

M.id = "buffers"

function M.save()
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })
  table.sort(buffers, function(a, b)
    return a.lastused > b.lastused
  end)

  local items = {}
  for _, buf in ipairs(buffers) do
    table.insert(items, {
      filepath = buf.name,
      nr = buf.bufnr,
    })
  end

  return items
end

function M.load(data)
  local function get_bufnr_by_filepath(filepath)
    for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
      if buf.name == filepath then
        return buf.bufnr
      end
    end
    return nil
  end

  -- Function to restore buffer order from saved list
  local function restore_buffer_order(saved_items)
    local original_bufnr = vim.fn.bufnr("%")

    -- Process in reverse order (least recent first)
    for i = #saved_items, 1, -1 do
      local item = saved_items[i]
      local target_bufnr = get_bufnr_by_filepath(item.filepath)

      if target_bufnr then
        logger.info("restoring %s", item.filepath)
        vim.cmd(string.format("noautocmd keepalt keepjumps silent buffer %d", target_bufnr))
        vim.cmd("sleep 1ms")
      end
    end

    -- Restore original buffer
    vim.cmd(string.format("noautocmd keepalt keepjumps silent buffer %d", original_bufnr))
  end

  restore_buffer_order(data)
end

return M
