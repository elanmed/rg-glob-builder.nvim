local M = {}

local validate = require "rg-glob-builder.validator".validate

--- @class ValidateOpts
--- @field schema Schema
--- @field value any
--- @field name string

--- @param opts ValidateOpts
M.validate = function(opts)
  if not validate(opts.schema, opts.value) then
    vim.notify(
      string.format(
        ("Malformed opts passed to %s! Expected to match schema: %s, received %s"):format(
          opts.name,
          vim.inspect(opts.schema),
          vim.inspect(opts.value)
        ),
        vim.inspect(opts.schema),
        vim.inspect(opts.value)
      ),
      vim.log.levels.ERROR
    )
    return false
  end

  return true
end

--- @class RgGlobBuilderOpts
--- @field auto_quote? boolean Quote the rg pattern and glob flags in single quotes. Defaults to true, except for in the `fzf_lua_adapter`.
--- @field custom_flags? RgGlobBuilderOptsCustomFlags Custom flags

--- @class RgGlobBuilderOptsCustomFlags
--- @field extension? string The flag to include or negate an extension to the glob pattern. Extensions are prefixed internally with "*.". Defaults to "-e"
--- @field file? string The flag to include or negate a file to the glob pattern. Files are passed without modification to the glob. Defaults to "-f"
--- @field directory? string The flag to include or negate a directory to the glob pattern. Extensions are updated internally to "**/[directory]/**". Defaults to "-d"
--- @field case_sensitive? string The flag to search case sensitively, adds the `--case-sensitive` flag. Defaults to "-c"
--- @field ignore_case? string The flag to search case insensitively, adds the `--case-ignore` flag. Defaults to "-nc"
--- @field whole_word? string The flag to search case by whole word, adds the `--word-regexp` flag. Defaults to "-w"
--- @field partial_word? string The flag to search case by partial word, removes the `--word-regexp` flag (searching by partial word is the default behavior in rg). Defaults to "-w"

--- @type Schema
M.opts_schema = {
  type = "table",
  optional = true,
  entries = {
    auto_quote = { type = "boolean", optional = true, },
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
  },
  exact = true,
}

--- @class FzfLuaAdapterOpts
--- @field fzf_lua_opts table
--- @field rg_glob_builder_opts RgGlobBuilderOpts

--- @type Schema
M.fzf_lua_adapter_opts_schema = {
  type = "table",
  optional = true,
  entries = {
    fzf_lua_opts = { type = "any", optional = true, },
    rg_glob_builder_opts = M.opts_schema,
  },
  exact = true,
}

--- @class TelescopeAdapterOpts
--- @field telescope_opts table
--- @field rg_glob_builder_opts RgGlobBuilderOpts

--- @type Schema
M.telescope_adapter_opts_schema = {
  type = "table",
  optional = true,
  entries = {
    telescope_opts = { type = "any", },
    rg_glob_builder_opts = M.opts_schema,
  },
  exact = true,
}

return M
