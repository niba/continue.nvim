---@class Continue.CustomHandler
local M = {}

M.id = "codecompanion"

function M.init(opts) end

function M.condition()
  local success, module = pcall(require, "codecompanion")

  return success and module
end

function M.save(opts)
  local history = {}
  local CodeCompanion = require("codecompanion")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local bo = vim.bo[buf]
      local buf_ft = bo.filetype

      if buf_ft == "codecompanion" then
        local chat = require("codecompanion").buf_get_chat(buf)
        local bufname = vim.api.nvim_buf_get_name(buf)
        local filename = vim.fn.fnamemodify(bufname, ":t")
        history[tostring(chat.id)] = {
          id = chat.id,
          messages = vim
            .iter(chat.messages)
            :map(function(message)
              return {
                content = message.content,
                role = message.role,
                opts = message.opts,
                cycle = message.cycle,
              }
            end)
            :totable(),
          name = filename,
          timestamp = tonumber(chat.id) or 0,
        }
      end
    end
  end

  local chat = CodeCompanion.last_chat()

  return {
    history = history,
    is_visible = chat and chat.ui:is_visible(),
  }
end

local function append_user_role(chat, role_display)
  local lines = {}
  table.insert(lines, "")
  table.insert(lines, "")
  chat.ui:set_header(lines, role_display)
  table.insert(lines, "")

  chat.ui:unlock_buf()
  local last_line, last_column, line_count = chat.ui:last()

  vim.api.nvim_buf_set_text(chat.bufnr, last_line, last_column, last_line, last_column, lines)

  chat.ui:follow()
end

function M.load(data)
  vim.schedule(function()
    local context_utils = require("codecompanion.utils.context")
    local config = require("codecompanion.config")
    local CodeCompanion = require("codecompanion")

    for id, chat_data in pairs(data.history) do
      local context = context_utils.get(vim.api.nvim_get_current_buf())
      local messages = chat_data.messages

      local should_append_user_header = #messages > 0 and messages[#messages].role ~= "user"
      if should_append_user_header then
        -- this is a hack, code companion ignores last message
        table.insert(messages, {
          role = "llm",
          content = "",
          opts = { visible = true },
        })
      end

      local chat = require("codecompanion.strategies.chat").new({
        context = context,
        messages = messages,
      })

      if should_append_user_header then
        append_user_role(chat, config.strategies.chat.roles["user"])
      end

      -- no option to pass title or id, maybe add PR to codecompanion
      -- chat.id = chat_data.id
      -- chat.title = chat_data.title
    end

    local chat = CodeCompanion.last_chat()
    if chat and not data.is_visible then
      chat.ui:hide()
    end
  end)
end

return M
