---@class Continue.PickerModule
local M = {}

M.name = "select"
M.enabled = true

function M.register()
  M.enabled = true
end

---@param opts Continue.PickerOpts
function M.pick(opts)
  local data = opts.get_data()

  vim.ui.select(data, {
    prompt = opts.title,
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice then
      opts.actions.confirm.handler(choice)
    end
  end)
end

return M
