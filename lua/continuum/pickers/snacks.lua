local sessions = require("continuum.sessions")
local config = require("continuum.config")
local consts = require("continuum.consts")

---@class Continuum.PickerModule
local M = {}

M.name = "snacks"
M.enabled = false

function M.register()
  local success, enabled = pcall(function()
    return Snacks.config.picker.enabled
  end)

  if not (success and enabled) then
    return
  end

  M.enabled = true
end

function M.pick(opts)
  local mappings = config.options.mappings

  Snacks.picker.pick({
    title = consts.PICKER_TITLE,
    layout = {
      preset = "select",
    },
    finder = function()
      local data = sessions.list(opts)

      return vim
        .iter(data)
        :map(function(session)
          return {
            text = sessions.display(session),
            session = session,
            path = session.path,
            name = session.name,
          }
        end)
        :totable()
    end,
    format = "text",
    win = {
      input = {
        keys = {
          [mappings.delete_session[2]] = { "delete", mode = mappings.delete_session[1] },
          ["dd"] = "delete",
        },
      },
      list = {
        keys = {
          ["dd"] = "delete",
        },
      },
    },
    actions = {
      confirm = function(picker, item)
        picker:close()
        vim.schedule(function()
          sessions.load(item.path)
        end)
      end,
      delete = function(picker, item)
        vim.schedule(function()
          sessions.delete(item.path, item.name)
          picker:find()
        end)
      end,
    },
  })
end

return M
