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

  -- based on the default grep rg_opts
  local default_rg_cmd = table.concat({
    "rg",
    "--column",
    "--line-number",
    "--no-heading",
    "--color=always",
    "--smart-case",
    "--max-columns=4096",
  }, " ")

  local default_opts = {
    cmd = default_rg_cmd,
    -- TODO: update to true and pass config with RPC
    multiprocess = false,
    fn_transform_cmd = function(prompt)
      local search = rg_glob_builder._parse_search(prompt, {
        auto_quote = opts.rg_glob_builder_opts.auto_quote,
        pattern_delimiter = opts.rg_glob_builder_opts.pattern_delimiter,
      })

      local glob_flags = rg_glob_builder.build(
        prompt,
        opts.rg_glob_builder_opts
      )

      if glob_flags == nil and opts.rg_glob_builder_opts.nil_unless_trailing_space then
        return nil, search.search
      end

      local cmd = default_rg_cmd .. " " .. glob_flags
      vim.notify(cmd, vim.log.levels.INFO)

      return cmd, search.search
    end,
  }

  return fzf_lua.live_grep(vim.tbl_deep_extend("force", default_opts, opts.fzf_lua_opts))
end

return M
