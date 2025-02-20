local telescope_picker = require("continuum.pickers.telescope")
local snacks_picker = require("continuum.pickers.snacks")
local select_picker = require("continuum.pickers.select")

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

function M.init_pickers()
  vim.iter(vim.tbl_values(pickers)):each(function(picker)
    picker.register()
  end)
end

return M

-- ["<c-a>"] = { "select_all", mode = { "n", "i" } },
