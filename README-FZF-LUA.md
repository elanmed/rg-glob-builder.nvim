# Using `rg-glob-builder` with `fzf-lua`

```lua
-- based on https://github.com/ibhagwan/fzf-lua/wiki/Advanced#example-1-live-ripgrep
local fzf_lua_adapter = function(rg_glob_builder_opts)
  local prev_rg_cmd_file = vim.fs.joinpath(vim.fn.stdpath "data", "rg-glob-builder", "prev_rg_cmd.txt")
  vim.fn.mkdir(vim.fs.dirname(prev_rg_cmd_file), "p")
  vim.fn.writefile({ "rg --line-number --column --hidden --color=always --max-columns=4096 -- ''", }, prev_rg_cmd_file)

  local fn_transform_cmd_str = string.format([[
    local query = ...
    local prev_rg_cmd_file = %q
    local rg_glob_builder_opts = vim.json.decode(%q)
    return require "get-fn-transform-cmd".get(prev_rg_cmd_file, rg_glob_builder_opts)(query)
  ]], prev_rg_cmd_file, vim.json.encode(rg_glob_builder_opts))

  local fn_transform_cmd_ok, fn_transform_cmd_res = pcall(loadstring, fn_transform_cmd_str)
  if not fn_transform_cmd_ok then
    error "Issue parsing `fn_transform_cmd_str`"
    return
  end

  local cmd = "rg --line-number --column --hidden --color=always --max-columns=4096 -- ''"
  local opts = {
    multiprocess = true,
    cmd = cmd,
    fn_transform_cmd = fn_transform_cmd_res,
  }

  require "fzf-lua".live_grep(opts)
end
```


```lua
-- path.to.get-fn-transform-cmd.lua
local M = {}

M.get = function(prev_rg_cmd_file, rg_glob_builder_opts)
  return function(query)
    local prompt = query
    local search, flags_prompt = prompt:match "(.-)%s-%-%-(.*)"
    local prev_rg_cmd = vim.fn.readfile(prev_rg_cmd_file)
    if search == nil then
      return "rg --line-number --column --hidden --color=always --max-columns=4096 -- ''"
    end

    if flags_prompt:sub(-1) ~= " " then
      return prev_rg_cmd[1]
    end

    local glob_flags = require "rg-glob-builder.builder".build(prompt, rg_glob_builder_opts)
    local cmd = "rg --line-number --column --hidden --color=always --max-columns=4096 " .. glob_flags
    vim.fn.writefile({ cmd, }, prev_rg_cmd_file)
    return cmd
  end
end

return M
```
