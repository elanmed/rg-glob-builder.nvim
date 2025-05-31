local M = {}

--- @param input_str string
--- @return table
M.split = function(input_str)
  local tbl = {}
  for str in input_str:gmatch "([^%s]+)" do
    table.insert(tbl, str)
  end
  return tbl
end

return M
