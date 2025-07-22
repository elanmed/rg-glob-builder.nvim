local M = {}

-- based on https://github.com/ibhagwan/fzf-lua/wiki/Advanced#example-1-live-ripgrep
--- @param opts FzfLuaAdapterOpts
M.fzf_lua_adapter = function(opts)
  -- can assume:
  -- opts is a table
  -- opts.rg_glob_builder_opts is a table
  -- opts.fzf_lua_opts is a table

  local fzf_lua_ok = pcall(require, "fzf-lua")
  if not fzf_lua_ok then
    error "rg_glob_builder.fzf_lua_adapter was called but fzf-lua is not installed!"
  end

  -- local custom_flags = h.default(opts.rg_glob_builder_opts.custom_flags, {})
  -- local header_tbl_line_one = {
  --   { custom_flags.extension or "-e", "*.[ext]", },
  --   { custom_flags.file or "-f", "file", },
  --   { custom_flags.directory or "-d", "**/[dir]/**", },
  -- }
  -- local header_tbl_line_two = {
  --   { custom_flags.case_sensitive or "-c", "case sensitive", },
  --   { custom_flags.ignore_case or "-nc", "case insensitive", },
  -- }
  -- local header_tbl_line_three = {
  --   { custom_flags.whole_word or "-w", "whole word", },
  --   { custom_flags.partial_word or "-nw", "partial word", },
  -- }
  --
  -- local function get_header_strs(header_tbl)
  --   local header_strs = {}
  --   for _, entry in ipairs(header_tbl) do
  --     local header_str = ("%s by %s"):format(
  --       fzf_lua.utils.ansi_from_hl("FzfLuaHeaderBind", entry[1]),
  --       fzf_lua.utils.ansi_from_hl("FzfLuaHeaderText", entry[2])
  --     )
  --     table.insert(header_strs, header_str)
  --   end
  --   return header_strs
  -- end
  --
  -- local header_strs_line_one = get_header_strs(header_tbl_line_one)
  -- local header_strs_line_two = get_header_strs(header_tbl_line_two)
  -- local header_strs_line_three = get_header_strs(header_tbl_line_three)

  local prev_rg_cmd_file = vim.fs.joinpath(vim.fn.stdpath "data", "rg-glob-builder", "tmp.txt")
  local fn_transform_cmd_str = string.format([[
    local query = ...
    local prev_rg_cmd_file = %q
    local rg_glob_builder_opts = vim.mpack.decode(%q)
    return require "rg-glob-builder.get-fn-transform-cmd".get(prev_rg_cmd_file, rg_glob_builder_opts)(query)
  ]], prev_rg_cmd_file, vim.mpack.encode(opts.rg_glob_builder_opts))
  local fn_transform_cmd_ok, fn_transform_cmd_res = pcall(loadstring, fn_transform_cmd_str)
  if not fn_transform_cmd_ok then
    error "ERROR! issue parsing `fn_transform_cmd_str`"
    return
  end

  local default_fzf_lua_opts = {
    multiprocess = true,
    cmd = "rg --line-number --column --hidden --color=always --max-columns=4096 -- ''",
    fn_transform_cmd = fn_transform_cmd_res,
  }

  require "fzf-lua".live_grep(
    vim.tbl_deep_extend("force", default_fzf_lua_opts, opts.fzf_lua_opts)
  )
end
return M
