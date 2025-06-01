local M = {}

-- based on https://github.com/nvim-telescope/telescope.nvim/pull/670
M.telescope_adapter = function(opts)
  local make_entry = require "telescope.make_entry"
  local pickers = require "telescope.pickers"
  local sorters = require "telescope.sorters"
  local finders = require "telescope.finders"
  local config_values = require "telescope.config".values

  local rg_glob_builder = require "rg-glob-builder.builder"
  local helpers = require "rg-glob-builder.helpers"

  opts = helpers.default(opts, {})

  local default_opts = {
    vimgrep_arguments = config_values.vimgrep_arguments,
    entry_maker = make_entry.gen_from_vimgrep(opts),
  }
  opts = vim.tbl_deep_extend("force", default_opts, opts)

  local function get_cmd(prompt)
    local vimgrep_flags = vim.deepcopy(opts.vimgrep_arguments)
    local glob_flags = rg_glob_builder.build {
      prompt = prompt,
    }
    local split_glob_flags = helpers.split(glob_flags or "")

    -- TODO: add config option for auto quoting
    local stripped_glob_flags = vim.tbl_map(function(split_glob_flag)
      local stripped = helpers.strip_single_quotes(split_glob_flag)
      return stripped
    end, split_glob_flags)

    local cmd_tbl = vim.iter {
      vimgrep_flags,
      stripped_glob_flags,
    }:flatten():totable()
    return cmd_tbl
  end

  pickers.new(opts, {
    finder = finders.new_job(get_cmd, opts.entry_maker, opts.max_results, opts.cwd),
    previewer = config_values.grep_previewer(opts),
    sorter = sorters.highlighter_only(opts),
  }):find()
end

return M
