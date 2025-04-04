local git = require("continuum.utils.git")

local T = MiniTest.new_set()

T["can parse git host"] = function()
  MiniTest.expect.equality(git.format_repo_host("aaa"), nil)
  MiniTest.expect.equality(
    git.format_repo_host("git@github.com:Test-org/ProjectName.git"),
    "Test-org/ProjectName"
  )
  MiniTest.expect.equality(
    git.format_repo_host("https://github.com/Test-org/ProjectName.nvim.git"),
    "Test-org/ProjectName.nvim"
  )
end

return T
