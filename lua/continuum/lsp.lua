local logger = require("continuum.logger.logger")
local M = {}

local active_servers = {}

local function capture_lsp_state()
  active_servers = {}
  local clients = vim.lsp.get_clients()

  for _, client in ipairs(clients) do
    table.insert(active_servers, {
      name = client.name,
      root_dir = client.config.root_dir,
    })
  end

  return #active_servers > 0
end

function M.stop_lsp()
  local clients = vim.lsp.get_clients()
  if #clients == 0 then
    return false
  end

  for _, client in ipairs(clients) do
    vim.lsp.stop_client(client.id)
  end

  vim.cmd("sleep 100m")
  return true
end

local function restart_lsp()
  if #active_servers == 0 then
    return false
  end

  local lspconfig = require("lspconfig")

  for _, server_info in ipairs(active_servers) do
    local server_name = server_info.name
    local config = {}

    if server_info.root_dir then
      config.root_dir = server_info.root_dir
    end

    if lspconfig[server_name] then
      lspconfig[server_name].setup(config)

      -- Force attach to open buffers
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd("LspStart " .. server_name)
          end)
        end
      end
    end
  end

  return true
end

function M.pre_session_load()
  capture_lsp_state()
  M.stop_lsp()

  logger.info("LSP servers stopped before session switch")
end

function M.post_session_load()
  collectgarbage("collect")

  vim.defer_fn(function()
    restart_lsp()
    logger.info("LSP servers restarted after session switch")
  end, 300)
end

return M
