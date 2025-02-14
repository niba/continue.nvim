local M = {}

function M.has_snack_picker()
  local success, enabled = pcall(function()
    return Snacks.config.picker.enabled
  end)

  return success and enabled
end

function M.has_telescope_picker()
  local success, telescope = pcall(require, "telescope")

  return success and telescope
end

function M.has_lazy_manager()
  return vim.g.lazy_did_setup
end

return M
