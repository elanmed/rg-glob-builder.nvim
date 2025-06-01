local M = {}

-- Based on https://github.com/ibhagwan/fzf-lua/wiki/Advanced#example-1-live-ripgrep
M.fzf_lua_adapter = function(opts)
  local helpers = require "rg-glob-builder.helpers"
  local rg_glob_builder = require "rg-glob-builder.builder"
  local fzf_lua = require "fzf-lua"

  opts = helpers.default(opts, {})

  local default_opts = {
    git_icons = true,
    file_icons = true,
    color_icons = true,
    actions = fzf_lua.defaults.actions.files,
    previewer = "builtin",
    fn_transform = function(x)
      return fzf_lua.make_entry.file(x, opts)
    end,
    fzf_opts = { ["--multi"] = true, },
  }
  opts = vim.tbl_deep_extend("force", default_opts, opts)

  if opts.git_icons then
    opts.fn_preprocess = function(o)
      opts.diff_files = fzf_lua.make_entry.preprocess(o).diff_files
      return opts
    end
  end

  -- found in the live_grep implementation, necessary to scroll the preview to the correct line with the bats previewer
  -- fzf-lua/lua/fzf-lua/providers/grep.lua
  opts = fzf_lua.core.set_fzf_field_index(opts)

  return fzf_lua.fzf_live(function(prompt)
    local flags = rg_glob_builder.build {
      prompt = prompt,
    }

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
  end, opts)
end

return M
