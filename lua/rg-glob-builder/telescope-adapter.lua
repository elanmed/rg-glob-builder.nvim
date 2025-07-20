local M = {}

-- based on https://github.com/nvim-telescope/telescope.nvim/pull/670
--- @param opts TelescopeAdapterOpts
M.telescope_adapter = function(opts)
  -- can assume:
  -- opts is a table
  -- opts.rg_glob_builder_opts is a table
  -- opts.telescope_opts is a table

  local telescope_ok = pcall(require, "telescope")
  if not telescope_ok then
    error "rg_glob_builder.telescope_adapter was called but telescope is not installed!"
  end

  local make_entry = require "telescope.make_entry"
  local pickers = require "telescope.pickers"
  local sorters = require "telescope.sorters"
  local finders = require "telescope.finders"
  local config_values = require "telescope.config".values
  local h = require "rg-glob-builder.helpers"
  local rg_glob_builder = require "rg-glob-builder.builder"

  local default_opts = {
    vimgrep_arguments = config_values.vimgrep_arguments,
    entry_maker = make_entry.gen_from_vimgrep(opts.telescope_opts),
  }
  opts.telescope_opts = vim.tbl_deep_extend("force", default_opts, opts.telescope_opts)
  local vimgrep_flags = vim.deepcopy(opts.telescope_opts.vimgrep_arguments)

  local init_rg_cmd_tbl = vim.iter {
    vimgrep_flags,
    "--",
    "''",
  }:flatten():totable()
  local init_rg_cmd_str = table.concat(init_rg_cmd_tbl, " ")
  local prev_rg_cmd_str = init_rg_cmd_str

  local function get_cmd(prompt)
    local search, flags_prompt = prompt:match "(.-)%s-%-%-(.*)"
    if search == nil then
      print "waiting for a trailing --"
      return nil
    end

    if flags_prompt:sub(-1) ~= " " then
      if prev_rg_cmd_str == init_rg_cmd_str then
        print(init_rg_cmd_str)
      else
        print("REPLAY: " .. prev_rg_cmd_str)
      end

      local prev_rg_cmd_tbl = h.split(prev_rg_cmd_str)
      return prev_rg_cmd_tbl
    end

    local glob_flags = rg_glob_builder.build(
      prompt,
      vim.tbl_deep_extend(
        "force",
        opts.rg_glob_builder_opts,
        { auto_quote = false, }
      )
    )

    local split_glob_flags = h.split(glob_flags)
    local cmd_tbl = vim.iter {
      vimgrep_flags,
      split_glob_flags,
    }:flatten():totable()

    local cmd_str = table.concat(cmd_tbl, " ")
    prev_rg_cmd_str = cmd_str
    print(cmd_str)

    return cmd_tbl
  end

  pickers.new(opts.telescope_opts, {
    finder = finders.new_job(
      get_cmd,
      opts.telescope_opts.entry_maker,
      opts.telescope_opts.max_results,
      opts.telescope_opts.cwd
    ),
    previewer = config_values.grep_previewer(opts.telescope_opts),
    sorter = sorters.highlighter_only(opts.telescope_opts),
  }):find()
end

return M
