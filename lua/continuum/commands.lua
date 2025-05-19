local continuum = require("continuum")
local config = require("continuum.config")
local logger = require("continuum.logger.logger")
local picker = require("continuum.pickers.picker")

return {
  {
    cmd = "ContinuumSave",
    callback = function(opts)
      continuum.save()
    end,
    opts = {
      desc = "Save session",
    },
  },
  {
    cmd = "ContinuumLoad",
    callback = function(opts)
      continuum.load()
    end,
    opts = {
      desc = "Load session",
    },
  },
  {
    cmd = "ContinuumDelete",
    callback = function(opts)
      continuum.delete()
    end,
    opts = {
      desc = "Delete session",
    },
  },

  {
    cmd = "ContinuumPicker",
    callback = function(opts)
      continuum.search({ picker = opts.args })
    end,
    opts = {
      desc = "Search current session",
      nargs = "?",
      complete = function(arg_lead, cmdline)
        if cmdline:match("^ContinuumPicker[!]*%s+%w*$") then
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
    cmd = "ContinuumToggleAutoSave",
    callback = function(opts)
      continuum.toggle_auto_save()
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
