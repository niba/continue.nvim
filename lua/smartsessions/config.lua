local utils = require("smartsessions.utils")

local M = {}

---@class SmartSessions.Config
M.default = {
  useBranch = true,
  useGitHost = true,
}

---@type SmartSessions.Config
M.options = {}

function M.setup(opts)
  M.options = utils.merge_deep({}, M.default, opts)
end

return M
