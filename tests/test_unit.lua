local rg_pattern_builder = require "rg-pattern-builder.init"
local expect = MiniTest.expect

local T = MiniTest.new_set()
T["build"] = MiniTest.new_set()
T["build"]["case"] = MiniTest.new_set()
T["build"]["case"]["should default to ignore case"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~", },
    [[--ignore-case 'require']]
  )
end
T["build"]["case"]["should override to case sensitive"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -c", },
    [[--case-sensitive 'require']]
  )
end
T["build"]["case"]["should override the override to ignore case"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -c -nc", },
    [[--ignore-case 'require']]
  )
end

T["build"]["whole word"] = MiniTest.new_set()
T["build"]["whole word"]["should default to not search by whole word"] = function()
  expect.no_equality(
    rg_pattern_builder.build { prompt = "~require~", },
    [[--ignore-case --word-regexp 'require']]
  )
end
T["build"]["whole word"]["should override to search by whole word"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -w", },
    [[--ignore-case --word-regexp 'require']]
  )
end
T["build"]["whole word"]["should override the override to not search by whole word"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -w -nw", },
    [[--ignore-case 'require']]
  )
end

T["build"]["file"] = MiniTest.new_set()
T["build"]["file"]["should include files"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -f init.lua", },
    [[--ignore-case 'require' -g '{init.lua}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -f init.lua README.md *.test.*", },
    [[--ignore-case 'require' -g '{init.lua,README.md,*.test.*}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -f init.lua -f README.md -f *.test.*", },
    [[--ignore-case 'require' -g '{init.lua,README.md,*.test.*}']]
  )
end
T["build"]["file"]["should exclude files"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -f !init.lua", },
    [[--ignore-case 'require' -g !'{init.lua}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -f !init.lua !README.md !*.test.*", },
    [[--ignore-case 'require' -g !'{init.lua,README.md,*.test.*}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -f !init.lua -f !README.md -f !*.test.*", },
    [[--ignore-case 'require' -g !'{init.lua,README.md,*.test.*}']]
  )
end
T["build"]["file"]["should include and exclude files"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -f README.md !init.lua", },
    [[--ignore-case 'require' -g '{README.md}' -g !'{init.lua}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -f README.md -f !init.lua", },
    [[--ignore-case 'require' -g '{README.md}' -g !'{init.lua}']]
  )
end

T["build"]["extensions"] = MiniTest.new_set()
T["build"]["extensions"]["should include extensions"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -e lua", },
    [[--ignore-case 'require' -g '{*.lua}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -e lua rb md", },
    [[--ignore-case 'require' -g '{*.lua,*.rb,*.md}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -e lua -e rb -e md", },
    [[--ignore-case 'require' -g '{*.lua,*.rb,*.md}']]
  )
end
T["build"]["extensions"]["should exclude extensions"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -e !lua", },
    [[--ignore-case 'require' -g !'{*.lua}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -e !lua !rb !md", },
    [[--ignore-case 'require' -g !'{*.lua,*.rb,*.md}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -e !lua -e !rb -e !md", },
    [[--ignore-case 'require' -g !'{*.lua,*.rb,*.md}']]
  )
end
T["build"]["extensions"]["should include and exclude extensions"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -e md !lua", },
    [[--ignore-case 'require' -g '{*.md}' -g !'{*.lua}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -e md -e !lua", },
    [[--ignore-case 'require' -g '{*.md}' -g !'{*.lua}']]
  )
end

T["build"]["dirs"] = MiniTest.new_set()
T["build"]["dirs"]["should include dirs"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -d plugins", },
    [[--ignore-case 'require' -g '{**/plugins/**}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -d plugins feature_*", },
    [[--ignore-case 'require' -g '{**/plugins/**,**/feature_*/**}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -d plugins -d feature_*", },
    [[--ignore-case 'require' -g '{**/plugins/**,**/feature_*/**}']]
  )
end
T["build"]["dirs"]["should exclude dirs"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -d !plugins", },
    [[--ignore-case 'require' -g !'{**/plugins/**}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -d !plugins !feature_*", },
    [[--ignore-case 'require' -g !'{**/plugins/**,**/feature_*/**}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -d !plugins -d !feature_*", },
    [[--ignore-case 'require' -g !'{**/plugins/**,**/feature_*/**}']]
  )
end
T["build"]["dirs"]["should include and exclude dirs"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -d plugins !feature_*", },
    [[--ignore-case 'require' -g '{**/plugins/**}' -g !'{**/feature_*/**}']]
  )
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -d plugins -d !feature_*", },
    [[--ignore-case 'require' -g '{**/plugins/**}' -g !'{**/feature_*/**}']]
  )
end

T["kitchen sink"] = function()
  expect.equality(
    rg_pattern_builder.build { prompt = "~require~ -e rb md !lua -d plugins !feature_* -f !*.test.* *_spec.rb", },
    [[--ignore-case 'require' -g '{*_spec.rb,*.rb,*.md,**/plugins/**}' -g !'{*.test.*,*.lua,**/feature_*/**}']]
  )
end

return T
