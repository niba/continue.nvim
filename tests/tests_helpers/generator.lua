local M = {}
local template = [[
#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = vim.fn.fnamemodify(".tests", ":p")
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

local plugin_dir = vim.uv.cwd()
{{cwd}}
-- Setup lazy.nvim
require("lazy.minit").setup({
  spec = {
    "nvim-lua/plenary.nvim",
    {
      dir = plugin_dir,
      name = "continuum",
      lazy = false,
      config = true,
      opts = {{opts}},
    },
  },
})
]]

local function generate_from_template(template, obj)
  -- Replace placeholders with object properties
  local result = template:gsub("{{(.-)}}", function(key)
    local value = obj
    for k in key:gmatch("[^.]+") do
      if type(value) ~= "table" then
        return "nil"
      end
      value = value[k]
    end

    if type(value) == "table" then
      return vim.inspect(value)
    elseif type(value) == "function" then
      return "function() ... end"
    elseif value == nil then
      return "nil"
    else
      return tostring(value)
    end
  end)

  return result
end

function M.generate_config(plugin_opts, cwd)
  local generated = generate_from_template(template, {
    opts = plugin_opts,
    cwd = cwd and string.format('vim.cmd("cd %s")', cwd) or "",
  })

  local file = io.open("tests/minit_generated.lua", "w")
  file:write(generated)
  file:close()
end

return M
