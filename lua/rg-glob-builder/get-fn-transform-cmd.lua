local M = {}

M.get = function(prev_rg_cmd_file, rg_glob_builder_opts)
  return function(query)
    local prompt = query
    local search, flags_prompt = prompt:match "(.-)%s-%-%-(.*)"
    if search == nil then
      return ""
    end

    local prev_rg_cmd = require "rg-glob-builder.fs".read(prev_rg_cmd_file)

    if flags_prompt:sub(-1) ~= " " then
      return prev_rg_cmd
    end

    local glob_flags = require "rg-glob-builder.builder".build(
      prompt,
      rg_glob_builder_opts
    )

    local h = require "rg-glob-builder.helpers"
    local cmd = table.concat({
      h.base_rg_cmd,
      glob_flags,
    }, " ")
    require "rg-glob-builder.fs".write { path = prev_rg_cmd_file, data = cmd, }
    return cmd
  end
end

return M
