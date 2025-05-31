local expect = MiniTest.expect
-- local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set()
T["placeholder"] = function()
  expect.equality("string", type "hello")
end

return T
