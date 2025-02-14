local sessions = require("continuum.sessions")
local consts = require("continuum.consts")

---@class Continuum.PickerModule
local M = {}

M.name = "select"
M.enabled = true

function M.register()
  M.enabled = true
end

function M.pick(opts)
  local existing_sessions = sessions.list(opts)

  vim.ui.select(existing_sessions, {
    prompt = consts.PICKER_TITLE,
    format_item = function(item)
      return sessions.display(item)
    end,
  }, function(choice)
    if choice then
      sessions.load(choice.path)
    end
  end)
end

return M
