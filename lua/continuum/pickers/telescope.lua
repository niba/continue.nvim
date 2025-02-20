---@class Continuum.PickerModule
local M = {}

M.name = "telescope"
M.enabled = false

function M.register()
  local success, telescope = pcall(require, "telescope")

  if not (success and telescope) then
    return
  end

  M.enabled = true

  telescope.load_extension("continuum")
end

---@param opts Continuum.PickerOpts
function M.pick(opts)
  local telescope_finders = require("telescope.finders")

  ---@param item Continuum.PickerItem
  local entry_maker = function(item)
    item.ordinal = item.text
    item.display = item.text

    return item
  end

  local finder_maker = function()
    local data = opts.get_data()

    return telescope_finders.new_table({
      results = data,
      entry_maker = entry_maker,
    })
  end

  local function delete_action(prompt_buffer)
    local action_state = require("telescope.actions.state")
    local current_picker = action_state.get_current_picker(prompt_buffer)

    current_picker:delete_selection(function(selection)
      if selection then
        return opts.actions.delete.handler(selection)
      end
    end)
  end

  local telescope_conf = require("telescope.config").values
  local telescope_actions = require("telescope.actions")
  local telescope_state = require("telescope.actions.state")

  require("telescope.pickers")
    .new(opts, {
      finder = finder_maker(),
      previewer = opts.preview,
      sorter = telescope_conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        map(opts.actions.delete.mode, opts.actions.delete.key, delete_action)

        telescope_actions.select_default:replace(function()
          telescope_actions.close(prompt_bufnr)
          local selection = telescope_state.get_selected_entry()
          opts.actions.confirm(selection)
        end)
        return true
      end,
    })
    :find()
end

return M
