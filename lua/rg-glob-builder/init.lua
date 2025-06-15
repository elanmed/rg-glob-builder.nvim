local M = {}

--- @type Schema
local setup_opts_schema = {
  type = "table",
  optional = true,
  entries = {
    pattern_delimiter = {
      type = function(val)
        return type(val) == "string" and #val == 1
      end,
      optional = true,
    },
    custom_flags = {
      type = "table",
      optional = true,
      entries = {
        extension = { type = "string", optional = true, },
        file = { type = "string", optional = true, },
        directory = { type = "string", optional = true, },
        case_sensitive = { type = "string", optional = true, },
        ignore_case = { type = "string", optional = true, },
        whole_word = { type = "string", optional = true, },
        partial_word = { type = "string", optional = true, },
      },
      exact = true,
    },
    nil_unless_trailing_space = { type = "boolean", optional = true, },
    auto_quote = { type = "boolean", optional = true, },
  },
  exact = true,
}


--- @class RgGlobBuilderSetupOpts
--- @field pattern_delimiter? string The single-char string to act as the delimiter for the pattern to pass to rg. Defaults to "~"
--- @field custom_flags? RgPatternBuilderSetupOptsCustomFlags Custom flags
--- @field nil_unless_trailing_space? boolean Return `nil` unless the final character is a trailing space. When updating the flags, this option will maintain the current search results until the update is complete. Defaults to `false`
--- @field auto_quote? boolean Quote the rg pattern and glob flags in single quotes. Defaults to true, except for in the `fzf_lua_adapter`.

--- @class RgPatternBuilderSetupOptsCustomFlags
--- @field extension? string The flag to include or negate an extension to the glob pattern. Extensions are prefixed internally with "*.". Defaults to "-e"
--- @field file? string The flag to include or negate a file to the glob pattern. Files are passed without modification to the glob. Defaults to "-f"
--- @field directory? string The flag to include or negate a directory to the glob pattern. Extensions are updated internally to "**/[directory]/**". Defaults to "-d"
--- @field case_sensitive? string The flag to search case sensitively, adds the `--case-sensitive` flag. Defaults to "-c"
--- @field ignore_case? string The flag to search case insensitively, adds the `--case-ignore` flag. Defaults to "-nc"
--- @field whole_word? string The flag to search case by whole word, adds the `--word-regexp` flag. Defaults to "-w"
--- @field partial_word? string The flag to search case by partial word, removes the `--word-regexp` flag (searching by partial word is the default behavior in rg). Defaults to "-w"

local setup_opts = {}

--- @param opts RgGlobBuilderSetupOpts
M.setup = function(opts)
  local validate = require "rg-glob-builder.validator".validate
  if not validate(setup_opts_schema, opts) then
    vim.notify(
      string.format(
        "Malformed opts passed to rg-glob-builder.setup! Expected to match schema: %s, received %s",
        vim.inspect(setup_opts_schema),
        vim.inspect(opts)
      ),
      vim.log.levels.ERROR
    )
    return
  end

  setup_opts = opts
end

--- @param opts RgGlobBuilderBuildOpts
M.build = function(opts)
  local validate = require "rg-glob-builder.validator".validate
  local helpers = require "rg-glob-builder.helpers"
  local builder = require "rg-glob-builder.builder"

  opts = helpers.default(opts, {})
  if not validate({ type = "string", }, opts.prompt) then
    vim.notify("opts.prompt is required in rg-glob-builder.build!", vim.log.levels.ERROR)
    return
  end

  local merged_opts = vim.tbl_deep_extend(
    "force",
    setup_opts,
    opts
  )
  return builder.build(merged_opts)
end

--- @type Schema
local fzf_lua_adapter_opts_schema = {
  type = "table",
  entries = {
    fzf_lua_opts = { type = "any", },
    rg_glob_builder_opts = setup_opts_schema,
  },
  exact = true,
}

--- @class FzfLuaAdapterOpts
--- @field fzf_lua_opts table
--- @field rg_glob_builder_opts RgGlobBuilderSetupOpts

--- @param opts FzfLuaAdapterOpts
M.fzf_lua_adapter = function(opts)
  local validate = require "rg-glob-builder.validator".validate
  if not validate(fzf_lua_adapter_opts_schema, opts) then
    vim.notify(
      string.format(
        "Malformed opts passed to rg-glob-builder.fzf_lua_adapter! Expected to match schema: %s, received %s",
        vim.inspect(fzf_lua_adapter_opts_schema),
        vim.inspect(opts)
      ),
      vim.log.levels.ERROR
    )
    return
  end

  local helpers = require "rg-glob-builder.helpers"

  opts = helpers.default(opts, {})
  local fzf_lua_opts = helpers.default(opts.fzf_lua_opts, {})
  local rg_glob_builder_opts = helpers.default(opts.rg_glob_builder_opts, {})

  local merged_rg_glob_builder_opts = vim.tbl_deep_extend(
    "force",
    setup_opts,
    rg_glob_builder_opts
  )
  return require "rg-glob-builder.fzf-lua-adapter".fzf_lua_adapter {
    fzf_lua_opts = fzf_lua_opts,
    rg_glob_builder_opts = merged_rg_glob_builder_opts,
  }
end

--- @type Schema
local telescope_adapter_opts_schema = {
  type = "table",
  entries = {
    telescope_opts = { type = "any", },
    rg_glob_builder_opts = setup_opts_schema,
  },
  exact = true,
}

--- @class TelescopeAdapterOpts
--- @field telescope_opts table
--- @field rg_glob_builder_opts RgGlobBuilderSetupOpts

--- @param opts TelescopeAdapterOpts
M.telescope_adapter = function(opts)
  local validate = require "rg-glob-builder.validator".validate
  if not validate(telescope_adapter_opts_schema, opts) then
    vim.notify(
      string.format(
        "Malformed opts passed to rg-glob-builder.telescope-adapter! Expected to match schema: %s, received %s",
        vim.inspect(telescope_adapter_opts_schema),
        vim.inspect(opts)
      ),
      vim.log.levels.ERROR
    )
    return
  end

  local helpers = require "rg-glob-builder.helpers"

  opts = helpers.default(opts, {})
  local telescope_opts = helpers.default(opts.telescope_opts, {})
  local rg_glob_builder_opts = helpers.default(opts.rg_glob_builder_opts, {})

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
