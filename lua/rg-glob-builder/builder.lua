local helpers = require "rg-glob-builder.helpers"

local M = {}

--- @class RecordFlagOpts
--- @field flag_val string
--- @field include_tbl table
--- @field negate_tbl table

--- @param opts RecordFlagOpts
local function record_flag(opts)
  if opts.flag_val:sub(1, 1) == "!" then
    if #opts.flag_val > 1 then
      table.insert(opts.negate_tbl, opts.flag_val:sub(2))
    end
  else
    table.insert(opts.include_tbl, opts.flag_val)
  end
end

--- @class ConstructRgFlagsOpts
--- @field dir_tbl table
--- @field file_tbl table
--- @field ext_tbl table
--- @field negate boolean
--- @field auto_quote? boolean

--- @param opts ConstructRgFlagsOpts
local function construct_rg_flags(opts)
  local ext_tbl_processed = vim.tbl_map(function(ext)
    return "*." .. ext
  end, opts.ext_tbl)

  local dir_tbl_processed = vim.tbl_map(function(dir)
    return string.format("**/%s/**", dir)
  end, opts.dir_tbl)

  local file_ext_dir_tbl = vim.iter { opts.file_tbl, ext_tbl_processed, dir_tbl_processed, }
      :flatten()
      :totable()

  if vim.tbl_count(file_ext_dir_tbl) > 0 then
    local flag = string.format("{%s}", table.concat(file_ext_dir_tbl, ","))
    local auto_quote = helpers.default(opts.auto_quote, true)
    if auto_quote then
      flag = string.format("'%s'", flag)
    end

    if opts.negate then
      flag = "!" .. flag
    end

    return "--glob " .. flag
  end

  return nil
end

--- @class ParseSearchOpts
--- @field prompt string
--- @field pattern_delimiter? string
--- @field auto_quote? boolean

--- @param opts ParseSearchOpts
local function parse_search(opts)
  local pattern_delimiter = helpers.default(opts.pattern_delimiter, "~")
  local end_tilde_index = opts.prompt:find(pattern_delimiter, 2)
  local end_index = end_tilde_index or (#opts.prompt + 1)
  local search = opts.prompt:sub(2, end_index - 1)

  local formatted_search = search
  local auto_quote = helpers.default(opts.auto_quote, true)
  if auto_quote then
    formatted_search = string.format("'%s'", formatted_search)
  end

  return { search = formatted_search, search_end_index = end_index, }
end

--- @class ParseFlagsOpts
--- @field tokens string[]
--- @field directory_flag string
--- @field extension_flag string
--- @field file_flag string
--- @field case_sensitive_flag? string
--- @field ignore_case_flag? string
--- @field whole_word_flag? string
--- @field partial_word_flag? string

--- @param opts ParseFlagsOpts
local function parse_flags(opts)
  local state = nil
  local parsed = {
    include_file = {},
    negate_file = {},
    include_dir = {},
    negate_dir = {},
    include_ext = {},
    negate_ext = {},
    case_flag = { "--ignore-case", },
    word_flag = { nil, },
  }
  local directory_flag = helpers.default(opts.directory_flag, "-d")
  local extension_flag = helpers.default(opts.extension_flag, "-e")
  local file_flag = helpers.default(opts.file_flag, "-f")
  local case_sensitive_flag = helpers.default(opts.case_sensitive_flag, "-c")
  local ignore_case_flag = helpers.default(opts.ignore_case_flag, "-nc")
  local whole_word_flag = helpers.default(opts.whole_word_flag, "-w")
  local partial_word_flag = helpers.default(opts.partial_word_flag, "-nw")

  for _, token in ipairs(opts.tokens) do
    if token == case_sensitive_flag then
      parsed.case_flag = { "--case-sensitive", }
      state = nil
    elseif token == ignore_case_flag then
      parsed.case_flag = { "--ignore-case", }
      state = nil
    elseif token == whole_word_flag then
      parsed.word_flag = { "--word-regexp", }
      state = nil
    elseif token == partial_word_flag then
      parsed.word_flag = { nil, }
      state = nil
    elseif token == file_flag then
      state = "file"
    elseif token == directory_flag then
      state = "dir"
    elseif token == extension_flag then
      state = "ext"
    elseif state then
      record_flag {
        flag_val = token,
        include_tbl = parsed["include_" .. state],
        negate_tbl = parsed["negate_" .. state],
      }
    end
  end

  return parsed
end

--- @class RgGlobBuilderBuildOpts: RgGlobBuilderSetupOpts
--- @field prompt string

--- @param opts RgGlobBuilderBuildOpts
M.build = function(opts)
  if opts.prompt == nil or opts.prompt == "" then
    return nil
  end

  local parsed_search = parse_search {
    prompt = opts.prompt,
    pattern_delimiter = opts.pattern_delimiter,
    auto_quote = opts.auto_quote,
  }

  local flags_prompt = opts.prompt:sub(parsed_search.search_end_index + 1)
  local nil_unless_trailing_space = helpers.default(opts.nil_unless_trailing_space, false)
  if nil_unless_trailing_space and flags_prompt:sub(-1) ~= " " then
    return nil
  end

  local tokens = helpers.split(flags_prompt)
  local custom_flags = helpers.default(opts.custom_flags, {})
  local flags = parse_flags {
    tokens = tokens,
    directory_flag = custom_flags.directory,
    extension_flag = custom_flags.extension,
    file_flag = custom_flags.file,
    case_sensitive_flag = custom_flags.case_sensitive,
    ignore_case_flag = custom_flags.ignore_case,
    partial_word_flag = custom_flags.partial_word,
    whole_word_flag = custom_flags.whole_word,
  }

  local include_flag = construct_rg_flags {
    negate = false,
    dir_tbl = flags.include_dir,
    file_tbl = flags.include_file,
    ext_tbl = flags.include_ext,
    auto_quote = opts.auto_quote,
  }

  local negate_flag = construct_rg_flags {
    negate = true,
    dir_tbl = flags.negate_dir,
    file_tbl = flags.negate_file,
    ext_tbl = flags.negate_ext,
    auto_quote = opts.auto_quote,
  }

  local cmd = vim.iter {
    flags.case_flag,
    flags.word_flag,
    include_flag,
    negate_flag,
    "--",
    parsed_search.search,
  }:flatten():totable()

  return table.concat(cmd, " ")
end

return M
