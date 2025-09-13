local M = {}

local setup_opts = {}

--- @param opts RgGlobBuilderOpts
M.setup = function(opts)
  local schemas = require "rg-glob-builder.schemas"
  if not schemas.validate { schema = schemas.opts_schema, value = opts, name = "rg-glob-builder.setup", } then
    return
  end

  setup_opts = opts
end

--- @param prompt string
--- @param opts RgGlobBuilderOpts
M.build = function(prompt, opts)
  local schemas = require "rg-glob-builder.schemas"
  if not schemas.validate { schema = schemas.opts_schema, value = opts, name = "rg-glob-builder.build", } then
    return
  end

  opts = opts or {}
  local merged_opts = vim.tbl_deep_extend(
    "force",
    setup_opts,
    opts
  )
  return require "rg-glob-builder.builder".build(prompt, merged_opts)
end

return M
