local fs = require("continuum.utils.fs")
local logger = require("continuum.logger.logger")
---@class Continuum.CustomHandler
local M = {}

M.id = "codecompanion"
M.config = { needs_dir = true }

function M.init(opts)
end


---@param opts Continuum.CustomHandlerOpts
function M.save(opts)
  local data = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local bo = vim.bo[buf]
      local buf_ft = bo.filetype

      if buf_ft == "codecompanion" then
        -- local chat = require("codecompanion").buf_get_chat(buf)
        local bufname = vim.api.nvim_buf_get_name(buf)
        local filename = vim.fn.fnamemodify(bufname, ":t")

        local output_file = filename ~= "" and filename or "unnamed_buffer.md"
        local output_path = vim.fn.resolve(fs.join_paths(opts.dir, output_file))

        local ok, err = pcall(function()
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          local file = io.open(output_path, "w")
          if not file then
            error("Could not open file for writing: " .. output_file)
          end
          file:write(table.concat(lines, "\n"))
          file:close()
        end)

        logger.info("file saved %s", ok)
        if ok then
          logger.info("in okay")
          local buffer_data = {
            filename = filename,
            options = {},
            variables = {},
            marks = {},
          }

          -- Safely get buffer options
          local ok_options = pcall(function()
            buffer_data.options = {
              filetype = bo.filetype,
              fileformat = bo.fileformat,
              fileencoding = bo.fileencoding,
              buftype = bo.buftype,
              modified = bo.modified,
              readonly = bo.readonly,
              modifiable = bo.modifiable,
              expandtab = bo.expandtab,
              shiftwidth = bo.shiftwidth,
              tabstop = bo.tabstop,
            }
          end)

          if not ok_options then
            buffer_data.options = {} -- Fallback to empty options
          end

          local ok_vars = pcall(function()
            local vars = {}
            for _, var in ipairs(vim.api.nvim_buf_get_var(buf, "")) do
              local ok, value = pcall(vim.api.nvim_buf_get_var, buf, var)
              if ok then
                vars[var] = value
              end
            end
            buffer_data.variables = vars
          end)

          if not ok_vars then
            buffer_data.variables = {} -- Fallback to empty variables
          end

          local ok_marks = pcall(function()
            buffer_data.marks = vim.fn.getmarklist(buf)
          end)

          if not ok_marks then
            buffer_data.marks = {} -- Fallback to empty marks
          end

          data[buffer_data.filename] = buffer_data
          logger.info("buffer data saved vars %s, marks %s", ok_vars, ok_marks)
        end
      end
    end
  end

  logger.info("codecompanion data %s", data)
  return data
end

function M.load(data, opts)
  for filename, buffer_data in pairs(data) do
    local bufnr = vim.api.nvim_create_buf(true, false)

    -- Read and set content
    local content_file = io.open(fs.join_paths(opts.dir, filename), "r")
    if content_file then
      local content = content_file:read("*a")
      content_file:close()

      local lines = vim.split(content, "\n")
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end

    if buffer_data.filename and buffer_data.filename ~= "" then
      pcall(vim.api.nvim_buf_set_name, bufnr, buffer_data.filename)
    end

    local bo = vim.bo[bufnr]
    for option, value in pairs(buffer_data.options) do
      pcall(function()
        bo[option] = value
      end)
    end

    for var_name, var_value in pairs(buffer_data.variables or {}) do
      pcall(vim.api.nvim_buf_set_var, bufnr, var_name, var_value)
    end

    for _, mark in ipairs(buffer_data.marks or {}) do
      pcall(vim.fn.setpos, mark.mark, { bufnr, mark.pos[1], mark.pos[2], mark.pos[3] })
    end
  end
end

return M
