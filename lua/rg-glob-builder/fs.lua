local M = {}

--- @param path string
M.read = function(path)
  -- io.open won't throw
  local file = io.open(path, "r")
  if file == nil then
    local h = require "rg-glob-builder.helpers"
    local cmd = table.concat({ h.base_rg_cmd, "-- ''", }, " ")
    return cmd
  end

  -- file:read won't throw
  local content = file:read "*a"
  file:close()
  return content
end

--- @class WriteOpts
--- @field path string
--- @field data string

--- @param opts WriteOpts
--- @return nil
M.write = function(opts)
  local h = require "rg-glob-builder.helpers"
  local path_dir = vim.fs.dirname(opts.path)
  local mkdir_res = vim.fn.mkdir(path_dir, "p")
  if mkdir_res == h.vimscript_false then
    error(("ERROR! issue calling mkdir with %s"):format(opts.path))
    return
  end

  -- io.open won't throw
  local file = io.open(opts.path, "w")
  if file == nil then
    error(("ERROR! issue calling io.open with %s"):format(opts.path))
    return
  end

  file:write(opts.data)
  file:close()
end

return M
