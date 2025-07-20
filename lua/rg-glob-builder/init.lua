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

  local h = require "rg-glob-builder.helpers"
  opts = h.default(opts, {})
  local merged_opts = vim.tbl_deep_extend(
    "force",
    setup_opts,
    opts
  )
  return require "rg-glob-builder.builder".build(prompt, merged_opts)
end

--- @param opts FzfLuaAdapterOpts
M.fzf_lua_adapter = function(opts)
  local schemas = require "rg-glob-builder.schemas"
  if not schemas.validate { schema = schemas.fzf_lua_adapter_opts_schema, value = opts, name = "rg-glob-builder.fzf_lua_adapter", } then
    return
  end

  local h = require "rg-glob-builder.helpers"
  opts = h.default(opts, {})
  local rg_glob_builder_opts = h.default(opts.rg_glob_builder_opts, {})
  local fzf_lua_opts = h.default(opts.fzf_lua_opts, {})

  local merged_rg_glob_builder_opts = vim.tbl_deep_extend(
    "force",
    setup_opts,
    rg_glob_builder_opts
  )
  return require "rg-glob-builder.fzf-lua-adapter".fzf_lua_adapter {
    rg_glob_builder_opts = merged_rg_glob_builder_opts,
    fzf_lua_opts = fzf_lua_opts,
  }
end

--- @param opts TelescopeAdapterOpts
M.telescope_adapter = function(opts)
  local schemas = require "rg-glob-builder.schemas"
  if not schemas.validate { schema = schemas.telescope_adapter_opts_schema, value = opts, name = "rg-glob-builder.telescope_adapter", } then
    return
  end

  local h = require "rg-glob-builder.helpers"
  opts = h.default(opts, {})
  local rg_glob_builder_opts = h.default(opts.rg_glob_builder_opts, {})
  local telescope_opts = h.default(opts.telescope_opts, {})

  local merged_rg_glob_builder_opts = vim.tbl_deep_extend(
    "force",
    setup_opts,
    rg_glob_builder_opts
  )

  return require "rg-glob-builder.telescope-adapter".telescope_adapter {
    rg_glob_builder_opts = merged_rg_glob_builder_opts,
    telescope_opts = telescope_opts,
  }
end

return M
