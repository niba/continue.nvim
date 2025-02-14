local sessions = require("continuum.sessions")
local consts = require("continuum.consts")
local config = require("continuum.config")
local utils = require("continuum.utils")

local function delete_action(prompt_buffer)
  local action_state = require("telescope.actions.state")
  local current_picker = action_state.get_current_picker(prompt_buffer)

  current_picker:delete_selection(function(selection)
    if selection then
      return sessions.delete(selection.path, selection.value)
    end
  end)
end

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

function M.pick(opts)
  local telescope_finders = require("telescope.finders")

  opts = utils.merge_deep({
    prompt_title = consts.PICKER_TITLE,
  }, opts)

  ---@param session Continuum.PickerData
  local entry_maker = function(session)
    return {
      ordinal = session.name,
      value = session.name,
      session = session,
      path = session.path,
      filename = session.name,
      display = sessions.display(session),
    }
  end

  local finder_maker = function()
    local existing_sessions = sessions.list(opts)

    return telescope_finders.new_table({
      results = existing_sessions,
      entry_maker = entry_maker,
    })
  end

  local telescope_conf = require("telescope.config").values
  local telescope_actions = require("telescope.actions")
  local telescope_state = require("telescope.actions.state")
  local mappings = config.options.mappings

  require("telescope.pickers")
    .new(opts, {
      finder = finder_maker(),
      previewer = false,
      sorter = telescope_conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        map(mappings.delete_session[1], mappings.delete_session[2], delete_action)

        telescope_actions.select_default:replace(function()
          telescope_actions.close(prompt_bufnr)
          local selection = telescope_state.get_selected_entry()
          sessions.load(selection.path)
        end)
        return true
      end,
    })
    :find()
end

return M
