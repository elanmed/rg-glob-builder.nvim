local M = {}

--- @param input_str string
M.split = function(input_str)
  local tbl = {}
  for str in input_str:gmatch "([^%s]+)" do
    table.insert(tbl, str)
  end
  return tbl
end

--- @param input_str string
M.strip_single_quotes = function(input_str)
  if input_str == nil then return input_str end
  if #input_str == 0 then return input_str end
  if input_str:sub(1, 1) == "'" and input_str:sub(-1) == "'" then
    return input_str:sub(2, #input_str - 1)
  end
  return input_str
end

--- @generic T
--- @param val T | nil
--- @param default_val T
--- @return T
M.default = function(val, default_val)
  if val == nil then
    return default_val
  end
  return val
end

M.vimscript_true = 1
M.vimscript_false = 0
M.base_rg_cmd = "rg --line-number --column --hidden --color=always --max-columns=4096"

return M
