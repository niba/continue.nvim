local continue = require("continue")
local config = require("continue.config")
local logger = require("continue.logger.logger")
local picker = require("continue.pickers.picker")

return {
  {
    cmd = "ContinueSave",
    callback = function(opts)
      continue.save()
    end,
    opts = {
      desc = "Save session",
    },
  },
  {
    cmd = "ContinueLoad",
    callback = function(opts)
      continue.load()
    end,
    opts = {
      desc = "Load session",
    },
  },
  {
    cmd = "ContinueDelete",
    callback = function(opts)
      continue.delete()
    end,
    opts = {
      desc = "Delete session",
    },
  },

  {
    cmd = "ContinuePicker",
    callback = function(opts)
      continue.search({ picker = opts.args })
    end,
    opts = {
      desc = "Search current session",
      nargs = "?",
      complete = function(arg_lead, cmdline)
        if cmdline:match("^ContinuePicker[!]*%s+%w*$") then
          return vim
            .iter(picker.supported_pickers)
            :filter(function(key)
              return key:find(arg_lead) ~= nil
            end)
            :totable()
        end
      end,
    },
  },
  {
    cmd = "ContinueToggleAutoSave",
    callback = function(opts)
      continue.toggle_auto_save()
      vim.notify(
        string.format("%s auto save", config.options.auto_save and "Enabled" or "Disabled"),
        vim.log.levels.INFO
      )
    end,
    opts = {
      desc = "Toggle auto save option",
    },
  },
}
