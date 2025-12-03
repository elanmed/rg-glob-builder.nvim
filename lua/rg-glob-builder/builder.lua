local M = {}

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

--- @class FormatRgFlagsOpts
--- @field dir_tbl table
--- @field file_tbl table
--- @field ext_tbl table
--- @field negate boolean

--- @param opts FormatRgFlagsOpts
--- @return table
local function format_rg_flags(opts)
  local exclude_symbol = opts.negate and "!" or ""

  local ext_tbl_processed = vim.tbl_map(function(ext)
    local formatted = ("%s*.%s"):format(exclude_symbol, ext)
    return vim.fn.shellescape "-g" .. " " .. vim.fn.shellescape(formatted)
  end, opts.ext_tbl)

  local dir_tbl_processed = vim.tbl_map(function(dir)
    local formatted = ("%s**/%s/**"):format(exclude_symbol, dir)
    return vim.fn.shellescape "-g" .. " " .. vim.fn.shellescape(formatted)
  end, opts.dir_tbl)

  local file_tbl_processed = vim.tbl_map(function(file)
    local formatted = ("%s%s"):format(exclude_symbol, file)
    return vim.fn.shellescape "-g" .. " " .. vim.fn.shellescape(formatted)
  end, opts.file_tbl)

  return vim.iter {
    ext_tbl_processed, dir_tbl_processed, file_tbl_processed,
  }:flatten():totable()
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
--- @field raw_input_flag? string

--- @param opts ParseFlagsOpts
local function parse_flags(opts)
  local state = nil
  local parsed = {
    include_file = {},
    exclude_file = {},
    include_dir = {},
    exclude_dir = {},
    include_ext = {},
    exclude_ext = {},
    raw_input = {},
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
  local raw_input_flag = default(opts.raw_input_flag, "-r")

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
    elseif token == raw_input_flag then
      state = "raw"
    elseif state then
      if state == "raw" then
        table.insert(parsed.raw_input, token)
      else
        if token:sub(1, 1) == "!" then
          if #token > 1 then
            table.insert(parsed["exclude_" .. state], token:sub(2))
          end
        else
          table.insert(parsed["include_" .. state], token)
        end
      end
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

  local tokens = vim.split(flags_prompt, "%s+", { trimempty = true, })
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
    raw_input_flag = custom_flags.raw_input,
  }

  local include_flags_formatted = format_rg_flags {
    negate = false,
    dir_tbl = flags.include_dir,
    file_tbl = flags.include_file,
    ext_tbl = flags.include_ext,
  }

  local exclude_flags_formatted = format_rg_flags {
    negate = true,
    dir_tbl = flags.exclude_dir,
    file_tbl = flags.exclude_file,
    ext_tbl = flags.exclude_ext,
  }

  local raw_input_formatted = vim.tbl_map(function(raw_input)
    return vim.fn.shellescape(raw_input)
  end, flags.raw_input)

  local cmd = vim.iter {
    flags.case_flag,
    flags.word_flag,
    raw_input_formatted,
    include_flags_formatted,
    exclude_flags_formatted,
    "--",
    search,
  }:flatten():totable()

  return table.concat(cmd, " ")
end

return M
