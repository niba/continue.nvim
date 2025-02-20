---@class Continuum.CustomHandler
local M = {}

M.id = "codecompanion"

function M.init(opts) end

function M.save(opts)
  local data = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local bo = vim.bo[buf]
      local buf_ft = bo.filetype

      if buf_ft == "codecompanion" then
        local chat = require("codecompanion").buf_get_chat(buf)
        local bufname = vim.api.nvim_buf_get_name(buf)
        local filename = vim.fn.fnamemodify(bufname, ":t")
        print(vim.inspect(chat.refs))
        data[tostring(chat.id)] = {
          id = chat.id,
          messages = vim
            .iter(chat.messages)
            :map(function(message)
              return {
                content = message.content,
                role = message.role,
                opts = message.opts,
              }
            end)
            :totable(),
          name = filename,
          timestamp = tonumber(chat.id) or 0,
        }
      end
    end
  end

  return data
end

function M.load(data)
  vim.schedule(function()
    local context_utils = require("codecompanion.utils.context")
    for id, chat_data in pairs(data) do
      local context = context_utils.get(vim.api.nvim_get_current_buf())
      local messages = chat_data.messages

      if #messages > 0 and messages[#messages].role ~= "user" then
        table.insert(messages, {
          role = "user",
          content = "\n\n",
          opts = { visible = true },
        })
      end

      local chat = require("codecompanion.strategies.chat").new({
        context = context,
        messages = messages,
      })
      chat.id = chat_data.id
      chat.title = chat_data.title
    end
  end)
end

return M
