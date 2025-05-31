local expect = MiniTest.expect
-- local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set()
T["build"] = MiniTest.new_set()
T["build"]["case"] = MiniTest.new_set()
T["build"]["case"]["should default to ignore case"] = function() end
T["build"]["case"]["should override to case sensitive"] = function() end

T["build"]["whole word"] = MiniTest.new_set()
T["build"]["whole word"]["should default to not search by whole word"] = function() end
T["build"]["whole word"]["should override to search by whole word"] = function() end

T["build"]["file"] = MiniTest.new_set()
T["build"]["file"]["should include files"] = function() end
T["build"]["file"]["should exclude files"] = function() end

T["build"]["dirs"] = MiniTest.new_set()
T["build"]["dirs"]["should include dirs"] = function() end
T["build"]["dirs"]["should exclude dirs"] = function() end

T["build"]["extensions"] = MiniTest.new_set()
T["build"]["extensions"]["should include extensions"] = function() end
T["build"]["extensions"]["should exclude extensions"] = function() end

T["kitchen sink"] = function() end

return T
