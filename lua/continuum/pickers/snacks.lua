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

---@param opts Continuum.PickerOpts
function M.pick(opts)
  local layout = opts.layout and opts.layout
    or opts.preview == false and { preset = "select" }
    or nil

  Snacks.picker.pick({
    title = opts.title,
    layout = layout,
    finder = function()
      return opts.get_data()
    end,
    format = "text",
    win = {
      input = {
        keys = {
          [opts.actions.delete.key] = { "delete", mode = opts.actions.delete.mode },
          [opts.actions.save_as.key] = { "save_as", mode = opts.actions.save_as.mode },
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
          opts.actions.confirm.handler(item)
        end)
      end,
      save_as = function(picker, item)
        vim.schedule(function()
          opts.actions.save_as.handler(item)
        end)
      end,
      delete = function(picker, item)
        vim.schedule(function()
          opts.actions.delete.handler(item)
          picker:find()
        end)
      end,
    },
  })
end

return M
