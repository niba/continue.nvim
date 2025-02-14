local M = {}

M.PLUGIN_NAME = "continuum"
M.SPECIAL_SEPARATOR = "__"
M.PAGER_MODE = false
M.PICKER_TITLE = "Sessions"

function M.enable_pager_mode()
  M.PAGER_MODE = true
end

return M
