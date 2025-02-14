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

-- local child = MiniTest.new_child_neovim()
--
-- local T = MiniTest.new_set({
--   hooks = {
--     pre_case = function()
--       child.restart({ "-l", "tests/minit.lua" })
--       child.lua([[M = require('continuum.git')]])
--     end,
--     post_once = child.stop,
--   },
-- })
--
-- T["can parse git host"] = function()
--   child.fn.system = function()
--     return "hahahha"
--   end
--   -- print(child.fn.system("test"))
--   print(child.lua("return M.repo_path()"))
--
--   MiniTest.expect.equality(child.lua("return M.repo_host()"), "aa")
-- end
--
-- return T
