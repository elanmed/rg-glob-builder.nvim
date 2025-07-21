local M = {}

-- based on https://github.com/ibhagwan/fzf-lua/wiki/Advanced#example-1-live-ripgrep
--- @param opts FzfLuaAdapterOpts
M.fzf_lua_adapter = function(opts)
  -- can assume:
  -- opts is a table
  -- opts.rg_glob_builder_opts is a table
  -- opts.fzf_lua_opts is a table

  local fzf_lua_ok, fzf_lua = pcall(require, "fzf-lua")
  if not fzf_lua_ok then
    error "rg_glob_builder.fzf_lua_adapter was called but fzf-lua is not installed!"
  end
  local rg_glob_builder = require "rg-glob-builder.builder"
  local h = require "rg-glob-builder.helpers"

  local custom_flags = h.default(opts.rg_glob_builder_opts.custom_flags, {})
  local header_tbl_line_one = {
    { custom_flags.extension or "-e", "*.[ext]", },
    { custom_flags.file or "-f", "file", },
    { custom_flags.directory or "-d", "**/[dir]/**", },
  }
  local header_tbl_line_two = {
    { custom_flags.case_sensitive or "-c", "case sensitive", },
    { custom_flags.ignore_case or "-nc", "case insensitive", },
  }
  local header_tbl_line_three = {
    { custom_flags.whole_word or "-w", "whole word", },
    { custom_flags.partial_word or "-nw", "partial word", },
  }

  local function get_header_strs(header_tbl)
    local header_strs = {}
    for _, entry in ipairs(header_tbl) do
      local header_str = ("%s by %s"):format(
        fzf_lua.utils.ansi_from_hl("FzfLuaHeaderBind", entry[1]),
        fzf_lua.utils.ansi_from_hl("FzfLuaHeaderText", entry[2])
      )
      table.insert(header_strs, header_str)
    end
    return header_strs
  end

  local header_strs_line_one = get_header_strs(header_tbl_line_one)
  local header_strs_line_two = get_header_strs(header_tbl_line_two)
  local header_strs_line_three = get_header_strs(header_tbl_line_three)

  local default_opts = {
    actions = fzf_lua.defaults.actions.files,
    previewer = "builtin",
    multiprocess = true,
    fn_transform = function(x)
      return require "fzf-lua".make_entry.file(x, opts.fzf_lua_opts)
    end,
    fzf_opts = {
      ["--multi"] = true,
      ["--header"] =
          table.concat(header_strs_line_one, " | ") .. "\n" ..
          table.concat(header_strs_line_two, " | ") .. "\n" ..
          table.concat(header_strs_line_three, " | "),
    },
  }
  opts.fzf_lua_opts = vim.tbl_deep_extend("force", default_opts, opts.fzf_lua_opts)

  -- found in the live_grep implementation, necessary to scroll the preview to the correct line with the bats previewer
  -- fzf-lua/lua/fzf-lua/providers/grep.lua
  opts.fzf_lua_opts = fzf_lua.core.set_fzf_field_index(opts.fzf_lua_opts)

  -- TODO: support an option to override this
  local base_rg_cmd = "rg --line-number --column --hidden --color=always --max-columns=4096 "
  local initial_rg_cmd = base_rg_cmd .. "-- ''"
  local prev_rg_cmd = initial_rg_cmd

  return fzf_lua.fzf_live(function(prompt_tbl)
    local prompt = prompt_tbl[1]
    local search, flags_prompt = prompt:match "(.-)%s-%-%-(.*)"
    if search == nil then
      print "waiting for a trailing --"
      return ""
    end

    if flags_prompt:sub(-1) ~= " " then
      if prev_rg_cmd == initial_rg_cmd then
        print(prev_rg_cmd)
      else
        print("REPLAY: " .. prev_rg_cmd)
      end
      return prev_rg_cmd
    end

    local glob_flags = rg_glob_builder.build(
      prompt,
      opts.rg_glob_builder_opts
    )

    -- based on the default grep rg_opts
    local cmd = base_rg_cmd .. glob_flags
    prev_rg_cmd = cmd
    print(cmd)

    return cmd
  end, opts.fzf_lua_opts)
end
return M
