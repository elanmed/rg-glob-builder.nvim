local M = {}

--- @type Schema
local opts_schema = {
  type = "table",
  optional = true,
  entries = {
    pattern_delimeter = {
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
    },
    nil_unless_trailing_space = { type = "boolean", optional = true, },
  },
}


--- @class RgPatternBuilderSetupOpts
--- @field pattern_delimeter? string The single-char string to act as the delimeter for the pattern to pass to rg. Defaults to "~"
--- @field custom_flags? RgPatternBuilderSetupOptsCustomFlags Custom flags
--- @field nil_unless_trailing_space? boolean Return `nil` unless the final character is a trailing space. When updating the flags, this option will maintain the current search results until the update is complete. Defaults to `false`

--- @class RgPatternBuilderSetupOptsCustomFlags
--- @field extension? string The flag to include or negate an extension to the glob pattern. Extensions are prefixed internally with "*.". Defaults to "-e"
--- @field file? string The flag to include or negate a file to the glob pattern. Files are passed without modification to the glob. Defaults to "-f"
--- @field directory? string The flag to include or negate a directory to the glob pattern. Extensions are updated internally to "**/[directory]/**". Defaults to "-d"
--- @field case_sensitive? string The flag to search case sensitively, adds the `--case-sensitive` flag. Defaults to "-c"
--- @field ignore_case? string The flag to search case insensitively, adds the `--case-ignore` flag. Defaults to "-nc"
--- @field whole_word? string The flag to search case by whole word, adds the `--word-regexp` flag. Defaults to "-w"
--- @field partial_word? string The flag to search case by partial word, removes the `--word-regexp` flag (searching by partial word is the default behavior in rg). Defaults to "-w"

local setup_opts = nil

--- @param opts RgPatternBuilderSetupOpts
M.setup = function(opts)
  local validate = require "rg-glob-builder.validator".validate
  if not validate(opts_schema, opts) then
    error(
      string.format(
        "Malformed opts! Expected to match schema: %s, received %s",
        vim.inspect(opts_schema),
        vim.inspect(opts)
      )
    )
  end

  setup_opts = opts
end

--- @param opts RgPatternBuilderBuildOpts
M.build = function(opts)
  local validate = require "rg-glob-builder.validator".validate
  local helpers = require "rg-glob-builder.helpers"
  local builder = require "rg-glob-builder.builder"

  opts = helpers.default(opts, {})
  if not validate({ type = "string", }, opts.prompt) then
    error "opts.prompt is required!"
  end

  local merged_opts = vim.tbl_deep_extend(
    "force",
    helpers.default(setup_opts, {}),
    opts
  )
  return builder.build(merged_opts)
end

M.fzf_lua_adapter = function(opts)
  return require "rg-glob-builder.fzf-lua-adapter".fzf_lua_adapter(opts)
end

return M
