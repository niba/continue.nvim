local telescope_picker = require("continue.pickers.telescope")
local snacks_picker = require("continue.pickers.snacks")
local select_picker = require("continue.pickers.select")
local consts = require("continue.consts")
local config = require("continue.config")
local sessions = require("continue.sessions")

local pickers = {
  telescope = telescope_picker,
  snacks = snacks_picker,
  native = select_picker,
}

local M = {}
---@alias Continue.SupportedPickers "telescope" | "snacks" | "mini" | "fzf" | "native"

---@class Continue.PickerItem
---@field [string] any
---@field value any
---@field text string
---@field path? string

---@class Continue.PickerKeymap
---@field key string
---@field mode? any
---@field handler fun(item: Continue.PickerItem): any

---@class Continue.PickerActions
---@field confirm Continue.PickerKeymap
---@field save_as Continue.PickerKeymap
---@field delete Continue.PickerKeymap
---@field [string] Continue.PickerKeymap

---@class Continue.PickerOpts
---@field get_data fun(opts?: any): Continue.PickerItem[]
---@field actions Continue.PickerActions
---@field title string
---@field layout any
---@field preview boolean
---
---
---@param opts Continue.PickerOpts
---@param force_picker Continue.SupportedPickers
function M.pick(opts, force_picker)
  if force_picker then
    pickers[force_picker].pick(opts)
    return
  end

  vim
    .iter(vim.tbl_values(pickers))
    :find(function(picker)
      return picker.enabled
    end)
    .pick(opts)
end

M.initialized = false

function M.init_pickers()
  if M.initialized then
    return
  end

  vim.iter(vim.tbl_values(pickers)):each(function(picker)
    picker.register()
  end)
end

M.supported_pickers = { "snacks", "telescope", "select" }

---@param opts? Continue.SearchOpts
function M.sessions(opts)
  M.pick({
    title = consts.PICKER_TITLE,
    preview = false,
    get_data = function()
      local data = sessions.list(opts)

      return vim
        .iter(data)
        :map(function(session)
          return {
            text = sessions.display(session),
            value = session,
            path = session.path,
          }
        end)
        :totable()
    end,
    actions = {
      confirm = {
        handler = function(item)
          sessions.load(item.path)
        end,
      },
      save_as = {
        handler = function(item)
          sessions.save(item.path)
          vim.notify("Session saved", vim.log.levels.INFO)
        end,
        mode = config.options.mappings.save_as_session[1],
        key = config.options.mappings.save_as_session[2],
      },
      delete = {
        handler = function(item)
          sessions.delete(item.path, item.value.name)
        end,
        mode = config.options.mappings.delete_session[1],
        key = config.options.mappings.delete_session[2],
      },
    },
  }, opts and opts.picker or nil)
end

return M
