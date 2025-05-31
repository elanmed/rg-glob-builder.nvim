local helpers = require "rg-glob-builder.helpers"
local builder = require "rg-glob-builder.builder"
local validate = require "rg-glob-builder.validator".validate

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
      extension = { type = "string", optional = true, },
      file = { type = "string", optional = true, },
      directory = { type = "string", optional = true, },
      case_sensitive = { type = "string", optional = true, },
      ignore_case = { type = "string", optional = true, },
      whole_word = { type = "string", optional = true, },
      partial_word = { type = "string", optional = true, },
    },
    nil_unless_trailing_space = { type = "boolean", optional = true, },
  },
}

--- @class RgPatternBuilderSetupOptsCustomFlags
--- @field extension? string
--- @field file? string
--- @field directory? string
--- @field case_sensitive? string
--- @field ignore_case? string
--- @field whole_word? string
--- @field partial_word? string

--- @class RgPatternBuilderSetupOpts
--- @field pattern_delimeter? string
--- @field custom_flags? RgPatternBuilderSetupOptsCustomFlags
--- @field nil_unless_trailing_space? boolean


local setup_opts = nil

--- @param opts RgPatternBuilderSetupOpts
M.setup = function(opts)
  if not validate(opts_schema, opts) then
    error(string.format("Expected opts of type: %s, received %s", vim.inspect(opts_schema), vim.inspect(opts)))
  end

  setup_opts = opts
end

--- @param opts RgPatternBuilderBuildOpts
M.build = function(opts)
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

return M
