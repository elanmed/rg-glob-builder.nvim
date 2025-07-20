local M = {}

-- based on https://github.com/ibhagwan/fzf-lua/wiki/Advanced#example-1-live-ripgrep
--- @param opts FzfLuaAdapterOpts
M.fzf_lua_adapter = function(opts)
  -- can assume the following are non-nil:
  -- opts
  -- opts.rg_glob_builder_opts
  -- opts.fzf_lua_opts

  local fzf_lua_ok, fzf_lua = pcall(require, "fzf-lua")
  if not fzf_lua_ok then
    error "rg_glob_builder.fzf_lua_adapter was called but fzf-lua is not installed!"
  end
  local rg_glob_builder = require "rg-glob-builder.builder"

  local custom_flags = require "rg-glob-builder.helpers".default(opts.rg_glob_builder_opts.custom_flags, {})
  local header_tbl_line_one = {
    [custom_flags.extension or "-e"] = "search by *.[extension]",
    [custom_flags.file or "-f"] = "search by file",
    [custom_flags.directory or "-d"] = "search by **/[directory]/**",
  }
  local header_tbl_line_two = {
    [custom_flags.case_sensitive or "-c"] = "search case sensitively",
    [custom_flags.ignore_case or "-nc"] = "search case insensitively",
    [custom_flags.whole_word or "-w"] = "search by whole word",
    [custom_flags.partial_word or "-nw"] = "search by partial word",
  }

  local function get_header_strs(header_tbl)
    local header_strs = {}
    for flag, desc in pairs(header_tbl) do
      local header_str = ("%s to %s"):format(
        fzf_lua.utils.ansi_from_hl("FzfLuaHeaderBind", flag),
        fzf_lua.utils.ansi_from_hl("FzfLuaHeaderText", desc)
      )
      table.insert(header_strs, header_str)
    end
    return header_strs
  end

  local header_strs_line_one = get_header_strs(header_tbl_line_one)
  local header_strs_line_two = get_header_strs(header_tbl_line_two)

  local default_opts = {
    actions = fzf_lua.defaults.actions.files,
    previewer = "builtin",
    multiprocess = true,
    fn_transform = function(x)
      return require "fzf-lua".make_entry.file(x, opts.fzf_lua_opts)
    end,
    fzf_opts = {
      ["--multi"] = true,
      ["--header"] = table.concat(header_strs_line_one, " | ") .. "\n" .. table.concat(header_strs_line_two, " | "),
    },
  }
  opts.fzf_lua_opts = vim.tbl_deep_extend("force", default_opts, opts.fzf_lua_opts)

  -- found in the live_grep implementation, necessary to scroll the preview to the correct line with the bats previewer
  -- fzf-lua/lua/fzf-lua/providers/grep.lua
  opts.fzf_lua_opts = fzf_lua.core.set_fzf_field_index(opts.fzf_lua_opts)

  local prev_cmd = ""

  return fzf_lua.fzf_live(function(prompt_tbl)
    local prompt = prompt_tbl[1]
    local glob_flags = rg_glob_builder.build(
      prompt,
      opts.rg_glob_builder_opts
    )

    if glob_flags == nil and opts.rg_glob_builder_opts.nil_unless_trailing_space then
      -- `fzf_live` used to support nil, hence the `nil_unless_trailing_space` name
      -- these days `fzf_live` throws on nil, but keeping track of the previous command works well
      vim.notify("waiting for a trailing space...", vim.log.levels.INFO)
      return prev_cmd
    end

    -- based on the default grep rg_opts
    local cmd_tbl = {
      "rg",
      "--line-number", "--column", -- necessary to scroll the preview to the correct line
      "--hidden",
      "--color=always",
      "--max-columns=4096",
      glob_flags,
    }
    local cmd = table.concat(cmd_tbl, " ")
    prev_cmd = cmd
    vim.notify(cmd, vim.log.levels.INFO)

    return cmd
  end, opts.fzf_lua_opts)
end
return M
