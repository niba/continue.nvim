local telescope_picker = require("continuum.pickers.telescope")
local snacks_picker = require("continuum.pickers.snacks")
local select_picker = require("continuum.pickers.select")
local consts = require("continuum.consts")
local config = require("continuum.config")
local sessions = require("continuum.sessions")

local pickers = {
  telescope = telescope_picker,
  snacks = snacks_picker,
  native = select_picker,
}

local M = {}
---@alias Continuum.SupportedPickers "telescope" | "snacks" | "mini" | "fzf" | "native"

---@class Continuum.PickerItem
---@field [string] any
---@field value any
---@field text string
---@field path? string

---@class Continuum.PickerKeymap
---@field key string
---@field mode? any
---@field handler fun(item: Continuum.PickerItem): any

---@class Continuum.PickerActions
---@field confirm Continuum.PickerKeymap
---@field save_as Continuum.PickerKeymap
---@field delete Continuum.PickerKeymap
---@field [string] Continuum.PickerKeymap

---@class Continuum.PickerOpts
---@field get_data fun(opts?: any): Continuum.PickerItem[]
---@field actions Continuum.PickerActions
---@field title string
---@field layout any
---@field preview boolean
---
---
---@param opts Continuum.PickerOpts
---@param force_picker Continuum.SupportedPickers
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

---@param opts? Continuum.SearchOpts
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
