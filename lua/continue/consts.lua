local system = require("continue.utils.system")
local M = {}

M.PLUGIN_NAME = "continue"
M.SPECIAL_SEPARATOR = "__"
M.PAGER_MODE = false
M.PICKER_TITLE = "Sessions"
M.IS_REPO = false
M.PROCESSING_IS_REPO = false

function M.enable_pager_mode()
  M.PAGER_MODE = true
end

function M.get_pager_mode()
  return M.PAGER_MODE or system.is_pager_mode()
end

function M.is_auto_session_disabled_by_option()
  return vim.g.auto_continue == false
end

return M
