return require("telescope").register_extension({
  setup = function() end,
  exports = {
    continue = require("continue.pickers.telescope").picker,
  },
})
