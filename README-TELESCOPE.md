# Using `rg-glob-builder` with `telescope`

```lua
--- @param input_str string
local split = function(input_str)
  local tbl = {}
  for str in input_str:gmatch "([^%s]+)" do
    table.insert(tbl, str)
  end
  return tbl
end

-- based on https://github.com/nvim-telescope/telescope.nvim/pull/670
local telescope_adapter = function(rg_glob_builder_opts, telescope_opts)
  rg_glob_builder_opts = rg_glob_builder_opts or {}
  telescope_opts = telescope_opts or {}

  local make_entry = require "telescope.make_entry"
  local pickers = require "telescope.pickers"
  local sorters = require "telescope.sorters"
  local finders = require "telescope.finders"
  local config_values = require "telescope.config".values
  local rg_glob_builder = require "rg-glob-builder.builder"

  local default_opts = {
    vimgrep_arguments = config_values.vimgrep_arguments,
    entry_maker = make_entry.gen_from_vimgrep(telescope_opts),
  }
  telescope_opts = vim.tbl_deep_extend("force", default_opts, telescope_opts)
  local vimgrep_flags = vim.deepcopy(telescope_opts.vimgrep_arguments)

  local init_rg_cmd_tbl = vim.iter {
    vimgrep_flags,
    "--",
    "''",
  }:flatten():totable()
  local prev_rg_cmd_tbl = init_rg_cmd_tbl

  local function get_cmd(prompt)
    local search, flags_prompt = prompt:match "(.-)%s-%-%-(.*)"
    if search == nil then
      return nil
    end

    if flags_prompt:sub(-1) ~= " " then
      return prev_rg_cmd_tbl
    end

    local glob_flags = rg_glob_builder.build(
      prompt,
      rg_glob_builder_opts,
      )
    )

    local split_glob_flags = split(glob_flags)
    local cmd_tbl = vim.iter {
      vimgrep_flags,
      split_glob_flags,
    }:flatten():totable()

    prev_rg_cmd_tbl = cmd_tbl
    return cmd_tbl
  end

  pickers.new(telescope_opts, {
    finder = finders.new_job(
      get_cmd,
      telescope_opts.entry_maker,
      telescope_opts.max_results,
      telescope_opts.cwd
    ),
    previewer = config_values.grep_previewer(telescope_opts),
    sorter = sorters.highlighter_only(telescope_opts),
  }):find()
end
```
