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
