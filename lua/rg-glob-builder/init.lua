local M = {}

--- @class RgGlobBuilderOpts
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
local opts_schema = {
  type = "table",
  optional = true,
  entries = {
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

--- @param prompt string
--- @param opts RgGlobBuilderOpts
M.build = function(prompt, opts)
  local notify_assert = require "rg-glob-builder.validator".notify_assert
  if not notify_assert { schema = opts_schema, value = opts, name = "[rg-glob-builder] build.opts", } then
    return
  end

  opts = opts or {}
  return require "rg-glob-builder.builder".build(prompt, opts)
end

return M
