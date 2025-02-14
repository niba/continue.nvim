return require("telescope").register_extension({
  setup = function() end,
  exports = {
    continuum = require("continuum.pickers.telescope").picker,
  },
})
