local utils = require("smartsessions.utils")

local T = MiniTest.new_set()

T["encode text"] = function()
  MiniTest.expect.equality(utils.encode("org/project_name"), "org_2Fproject_name")
end

T["decode text"] = function()
  MiniTest.expect.equality(utils.decode("org_2Fproject_name"), "org/project_name")
end

T["shallow merge"] = function()
  MiniTest.expect.equality(
    utils.merge({
      a = 6,
      b = 3,
    }, {
      a = 1,
      c = 3,
    }),
    {
      a = 1,
      b = 3,
      c = 3,
    }
  )
end

return T
