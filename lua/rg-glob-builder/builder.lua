local M = {}

--- @param input_str string
local split = function(input_str)
  local tbl = {}
  for str in input_str:gmatch "([^%s]+)" do
    table.insert(tbl, str)
  end
  return tbl
end

--- @generic T
--- @param val T | nil
--- @param default_val T
--- @return T
local default = function(val, default_val)
  if val == nil then
    return default_val
  end
  return val
end

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

--- @param opts ConstructRgFlagsOpts
--- @return string | nil
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
    local negate_symbol = opts.negate and "!" or ""
    local flag = ""

    for _, glob in ipairs(file_ext_dir_tbl) do
      flag = flag .. "-g " .. vim.fn.shellescape(negate_symbol .. glob) .. " "
    end
    return vim.trim(flag)
  end

  return nil
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
  local directory_flag = default(opts.directory_flag, "-d")
  local extension_flag = default(opts.extension_flag, "-e")
  local file_flag = default(opts.file_flag, "-f")
  local case_sensitive_flag = default(opts.case_sensitive_flag, "-c")
  local ignore_case_flag = default(opts.ignore_case_flag, "-nc")
  local whole_word_flag = default(opts.whole_word_flag, "-w")
  local partial_word_flag = default(opts.partial_word_flag, "-nw")

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

--- @param prompt string
--- @param opts RgGlobBuilderOpts
M.build = function(prompt, opts)
  -- can assume opts is a table

  prompt = default(prompt, "")
  -- https://github.com/ibhagwan/fzf-lua/wiki/Advanced#example-custom-glob-parsing-for-git-grep
  local search, flags_prompt = prompt:match "(.-)%s-%-%-(.*)"
  search = search or ""
  search = vim.fn.shellescape(search)
  flags_prompt = flags_prompt or ""

  local tokens = split(flags_prompt)
  local custom_flags = default(opts.custom_flags, {})
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
  }

  local negate_flag = construct_rg_flags {
    negate = true,
    dir_tbl = flags.negate_dir,
    file_tbl = flags.negate_file,
    ext_tbl = flags.negate_ext,
  }

  local cmd = vim.iter {
    flags.case_flag,
    flags.word_flag,
    include_flag,
    negate_flag,
    "--",
    search,
  }:flatten():totable()

  return table.concat(cmd, " ")
end

return M
