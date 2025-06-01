local M = {}

-- based on https://github.com/ibhagwan/fzf-lua/wiki/Advanced#example-1-live-ripgrep

--- @param opts FzfLuaAdapterOpts
M.fzf_lua_adapter = function(opts)
  local rg_glob_builder = require "rg-glob-builder.builder"
  local fzf_lua = require "fzf-lua"

  local default_opts = {
    git_icons = true,
    file_icons = true,
    color_icons = true,
    actions = fzf_lua.defaults.actions.files,
    previewer = "builtin",
    fn_transform = function(x)
      return fzf_lua.make_entry.file(x, opts.fzf_lua_opts)
    end,
    fzf_opts = { ["--multi"] = true, },
  }
  opts.fzf_lua_opts = vim.tbl_deep_extend("force", default_opts, opts.fzf_lua_opts)

  if opts.fzf_lua_opts.git_icons then
    opts.fzf_lua_opts.fn_preprocess = function(o)
      opts.fzf_lua_opts.diff_files = fzf_lua.make_entry.preprocess(o).diff_files
      return opts.fzf_lua_opts
    end
  end

  -- found in the live_grep implementation, necessary to scroll the preview to the correct line with the bats previewer
  -- fzf-lua/lua/fzf-lua/providers/grep.lua
  opts.fzf_lua_opts = fzf_lua.core.set_fzf_field_index(opts.fzf_lua_opts)

  return fzf_lua.fzf_live(function(prompt)
    local flags = rg_glob_builder.build(
      vim.tbl_deep_extend(
        "force",
        opts.rg_glob_builder_opts,
        { prompt = prompt, }
      )
    )

    local cmd_tbl = vim.iter {
      "rg",
      "--line-number", "--column", -- necessary to scroll the preview to the correct line
      "--hidden",
      "--color=always",
      flags,
    }:flatten():totable()
    local cmd = table.concat(cmd_tbl, " ")

    if cmd then print(cmd) end
    return cmd
  end, opts.fzf_lua_opts)
end

return M
