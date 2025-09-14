local M = {}

local setup_opts = {}

--- @param opts RgGlobBuilderOpts
M.setup = function(opts)
  local schemas = require "rg-glob-builder.schemas"
  local notify_assert = require "rg-glob-builder.validator".notify_assert
  if not notify_assert { schema = schemas.opts_schema, value = opts, name = "[rg-glob-builder.nvim] setup.opts", } then
    return
  end

  setup_opts = opts
end

--- @param prompt string
--- @param opts RgGlobBuilderOpts
M.build = function(prompt, opts)
  local schemas = require "rg-glob-builder.schemas"
  local notify_assert = require "rg-glob-builder.validator".notify_assert
  if not notify_assert { schema = schemas.opts_schema, value = opts, name = "[rg-glob-builder] build.opts", } then
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
