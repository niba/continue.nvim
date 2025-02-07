local M = {}

local augroup = vim.api.nvim_create_augroup("SmartSessions", { clear = true })

-- write better logic
function M.on_start(fn)
  -- support other package managers
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyVimStarted",
    -- pattern = "LazyDone",
    callback = function()
      fn()
    end,
    group = augroup,
    once = true,
  })
end

function M.on_end(fn)
  vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
    pattern = "*",
    callback = function()
      fn()
    end,
    group = augroup,
    once = true,
  })
end

return M
