local M = {}

-- based on https://github.com/nvim-telescope/telescope.nvim/pull/670

--- @param opts TelescopeAdapterOpts
M.telescope_adapter = function(opts)
  local make_entry = require "telescope.make_entry"
  local pickers = require "telescope.pickers"
  local sorters = require "telescope.sorters"
  local finders = require "telescope.finders"
  local config_values = require "telescope.config".values
  local helpers = require "rg-glob-builder.helpers"
  local rg_glob_builder = require "rg-glob-builder.builder"

  local default_opts = {
    vimgrep_arguments = config_values.vimgrep_arguments,
    entry_maker = make_entry.gen_from_vimgrep(opts.telescope_opts),
  }
  opts.telescope_opts = vim.tbl_deep_extend("force", default_opts, opts.telescope_opts)

  local function get_cmd(prompt)
    local vimgrep_flags = vim.deepcopy(opts.telescope_opts.vimgrep_arguments)
    local glob_flags = rg_glob_builder.build(
      vim.tbl_deep_extend(
        "force",
        opts.rg_glob_builder_opts,
        { prompt = prompt, auto_quote = false, }
      )
    )
    if glob_flags == nil and opts.rg_glob_builder_opts.nil_unless_trailing_space then
      return nil
    end

    local split_glob_flags = helpers.split(glob_flags or "")

    local cmd_tbl = vim.iter {
      vimgrep_flags,
      split_glob_flags,
    }:flatten():totable()
    local cmd = table.concat(cmd_tbl, " ")
    print(cmd)

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
