local expect = MiniTest.expect
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set {
  hooks = {
    pre_case = function()
      child.restart { "-u", "scripts/minimal_init.lua", }
      child.lua [[M = require "rg-glob-builder"]]
    end,
    post_once = child.stop,
  },
}
T["build"] = MiniTest.new_set()

T["build"]["setup opts"] = MiniTest.new_set()
T["build"]["setup opts"]["case"] = function()
  child.lua [[ M.setup { custom_flags = { case_sensitive = "--case", ignore_case = "--no-case", }, } ]]

  expect.equality(
    child.lua [[ return M.build "require -- --case" ]],
    [[--case-sensitive -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- --no-case" ]],
    [[--ignore-case -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- --case --no-case" ]],
    [[--ignore-case -- 'require']]
  )
end
T["build"]["setup opts"]["whole word"] = function()
  child.lua [[ M.setup { custom_flags = { whole_word = "--whole-word", partial_word = "--partial-word", }, } ]]

  expect.equality(
    child.lua [[ return M.build "require -- --whole-word" ]],
    [[--ignore-case --word-regexp -- 'require']]
  )
  expect.no_equality(
    child.lua [[ return M.build "require -- --partial-word" ]],
    [[--ignore-case --word-regexp -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- --whole-word --partial-word" ]],
    [[--ignore-case -- 'require']]
  )
end
T["build"]["setup opts"]["extension"] = function()
  child.lua [[ M.setup { custom_flags = { extension = "--ext", }, } ]]
  expect.equality(
    child.lua [[ return M.build "require -- --ext md !lua"]],
    [[--ignore-case -g '*.md' -g '!*.lua' -- 'require']]
  )
end
T["build"]["setup opts"]["file"] = function()
  child.lua [[ M.setup { custom_flags = { file = "--file", }, } ]]
  expect.equality(
    child.lua [[ return M.build "require -- --file README.md !init.lua"]],
    [[--ignore-case -g 'README.md' -g '!init.lua' -- 'require']]
  )
end
T["build"]["setup opts"]["directory"] = function()
  child.lua [[ M.setup { custom_flags = { directory = "--dir", }, } ]]
  expect.equality(
    child.lua [[ return M.build "require -- --dir plugins !feature_*"]],
    [[--ignore-case -g '**/plugins/**' -g '!**/feature_*/**' -- 'require']]
  )
end
T["build"]["setup opts"]["auto quote"] = function()
  child.lua [[ M.setup { auto_quote = false, } ]]
  expect.equality(
    child.lua [[ return M.build "require -- -e lua !rb"]],
    [[--ignore-case -g *.lua -g !*.rb -- require]]
  )
end

T["build"]["local opts"] = MiniTest.new_set()
T["build"]["local opts"]["case"] = function()
  child.lua [[ M.setup { custom_flags = { case_sensitive = "--case", ignore_case = "--no-case", }, } ]]

  expect.equality(
    child.lua [[ return M.build "require -- --case" ]],
    [[--case-sensitive -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- --no-case" ]],
    [[--ignore-case -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- --case --no-case" ]],
    [[--ignore-case -- 'require']]
  )
end
T["build"]["local opts"]["whole word"] = function()
  expect.equality(
    child.lua [[ return M.build("require -- --whole-word", { custom_flags = { whole_word = "--whole-word", partial_word = "--partial-word", }, }) ]],
    [[--ignore-case --word-regexp -- 'require']]
  )
  expect.no_equality(
    child.lua [[ return M.build("require -- --partial-word", { custom_flags = { whole_word = "--whole-word", partial_word = "--partial-word", }, }) ]],
    [[--ignore-case --word-regexp -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build("require -- --whole-word --partial-word", { custom_flags = { whole_word = "--whole-word", partial_word = "--partial-word", }, }) ]],
    [[--ignore-case -- 'require']]
  )
end
T["build"]["local opts"]["extension"] = function()
  expect.equality(
    child.lua [[ return M.build("require -- --ext md !lua", { custom_flags = { extension = "--ext", }, })]],
    [[--ignore-case -g '*.md' -g '!*.lua' -- 'require']]
  )
end
T["build"]["local opts"]["file"] = function()
  expect.equality(
    child.lua [[ return M.build("require -- --file README.md !init.lua", { custom_flags = { file = "--file", }, })]],
    [[--ignore-case -g 'README.md' -g '!init.lua' -- 'require']]
  )
end
T["build"]["local opts"]["directory"] = function()
  expect.equality(
    child.lua [[ return M.build("require -- --dir plugins !feature_*", { custom_flags = { directory = "--dir", }, })]],
    [[--ignore-case -g '**/plugins/**' -g '!**/feature_*/**' -- 'require']]
  )
end
T["build"]["local opts"]["auto quote"] = function()
  expect.equality(
    child.lua [[ return M.build("require -- -e lua !rb", { auto_quote = false })]],
    [[--ignore-case -g *.lua -g !*.rb -- require]]
  )
end

T["build"]["local opts overriding setup opts"] = MiniTest.new_set()
T["build"]["local opts overriding setup opts"]["case"] = function()
  child.lua [[ M.setup { custom_flags = { case_sensitive = "--case", ignore_case = "--no-case", }, } ]]

  expect.equality(
    child.lua [[ return M.build("require -- --c", { custom_flags = { case_sensitive = "--c", ignore_case = "--noc", }, }) ]],
    [[--case-sensitive -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build("require -- --noc", { custom_flags = { case_sensitive = "--case", ignore_case = "--no-case", }, }) ]],
    [[--ignore-case -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build("require -- --c --noc", { custom_flags = { case_sensitive = "--case", ignore_case = "--no-case", }, }) ]],
    [[--ignore-case -- 'require']]
  )
end
T["build"]["local opts overriding setup opts"]["whole word"] = function()
  child.lua [[ M.setup { custom_flags = { whole_word = "--whold-word", partial_word = "--partial-word", }, } ]]
  expect.equality(
    child.lua [[ return M.build("require -- --w", { custom_flags = { whole_word = "--w", }, }) ]],
    [[--ignore-case --word-regexp -- 'require']]
  )
  expect.no_equality(
    child.lua [[ return M.build("require -- --p", { custom_flags = { partial_word = "--p", },  }) ]],
    [[--ignore-case --word-regexp -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build("require -- --w --p", { custom_flags = { whole_word = "--w", partial_word = "--p", }, }) ]],
    [[--ignore-case -- 'require']]
  )
end
T["build"]["local opts overriding setup opts"]["extension"] = function()
  child.lua [[ M.setup { custom_flags = { extension = "--e" }, } ]]
  expect.equality(
    child.lua [[ return M.build("require -- --ext md !lua", { custom_flags = { extension = "--ext", }, })]],
    [[--ignore-case -g '*.md' -g '!*.lua' -- 'require']]
  )
end
T["build"]["local opts overriding setup opts"]["file"] = function()
  child.lua [[ M.setup { custom_flags = { file = "--f" }, } ]]
  expect.equality(
    child.lua [[ return M.build("require -- --file README.md !init.lua", { custom_flags = { file = "--file", }, })]],
    [[--ignore-case -g 'README.md' -g '!init.lua' -- 'require']]
  )
end
T["build"]["local opts overriding setup opts"]["directory"] = function()
  child.lua [[ M.setup { custom_flags = { directory = "--d" }, } ]]
  expect.equality(
    child.lua [[ return M.build("require -- --dir plugins !feature_*", { custom_flags = { directory = "--dir", }, })]],
    [[--ignore-case -g '**/plugins/**' -g '!**/feature_*/**' -- 'require']]
  )
end
T["build"]["local opts overriding setup opts"]["auto quote"] = function()
  child.lua [[ M.setup { auto_quote = true, } ]]
  expect.equality(
    child.lua [[ return M.build("require -- -e lua !rb", { auto_quote = false })]],
    [[--ignore-case -g *.lua -g !*.rb -- require]]
  )
end

T["build"]["default opts"] = MiniTest.new_set()
T["build"]["default opts"]["case"] = MiniTest.new_set()
T["build"]["default opts"]["case"]["should default to ignore case"] = function()
  expect.equality(
    child.lua [[ return M.build "require --"]],
    [[--ignore-case -- 'require']]
  )
end
T["build"]["default opts"]["case"]["should override to case sensitive"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -c"]],
    [[--case-sensitive -- 'require']]
  )
end
T["build"]["default opts"]["case"]["should override the override to ignore case"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -c -nc"]],
    [[--ignore-case -- 'require']]
  )
end

T["build"]["default opts"]["whole word"] = MiniTest.new_set()
T["build"]["default opts"]["whole word"]["should default to not search by whole word"] = function()
  expect.no_equality(
    child.lua [[ return M.build "require --"]],
    [[--ignore-case --word-regexp -- 'require']]
  )
end
T["build"]["default opts"]["whole word"]["should override to search by whole word"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -w"]],
    [[--ignore-case --word-regexp -- 'require']]
  )
end
T["build"]["default opts"]["whole word"]["should override the override to not search by whole word"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -w -nw"]],
    [[--ignore-case -- 'require']]
  )
end

T["build"]["default opts"]["file"] = MiniTest.new_set()
T["build"]["default opts"]["file"]["should include files"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -f init.lua"]],
    [[--ignore-case -g 'init.lua' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -f init.lua README.md *.test.*"]],
    [[--ignore-case -g 'init.lua' -g 'README.md' -g '*.test.*' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -f init.lua -f README.md -f *.test.*"]],
    [[--ignore-case -g 'init.lua' -g 'README.md' -g '*.test.*' -- 'require']]
  )
end
T["build"]["default opts"]["file"]["should exclude files"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -f !init.lua"]],
    [[--ignore-case -g '!init.lua' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -f !init.lua !README.md !*.test.*"]],
    [[--ignore-case -g '!init.lua' -g '!README.md' -g '!*.test.*' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -f !init.lua -f !README.md -f !*.test.*"]],
    [[--ignore-case -g '!init.lua' -g '!README.md' -g '!*.test.*' -- 'require']]
  )
end
T["build"]["default opts"]["file"]["should include and exclude files"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -f README.md !init.lua"]],
    [[--ignore-case -g 'README.md' -g '!init.lua' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -f README.md -f !init.lua"]],
    [[--ignore-case -g 'README.md' -g '!init.lua' -- 'require']]
  )
end

T["build"]["default opts"]["extension"] = MiniTest.new_set()
T["build"]["default opts"]["extension"]["should include extensions"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -e lua"]],
    [[--ignore-case -g '*.lua' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -e lua rb md"]],
    [[--ignore-case -g '*.lua' -g '*.rb' -g '*.md' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -e lua -e rb -e md"]],
    [[--ignore-case -g '*.lua' -g '*.rb' -g '*.md' -- 'require']]
  )
end
T["build"]["default opts"]["extension"]["should exclude extensions"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -e !lua"]],
    [[--ignore-case -g '!*.lua' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -e !lua !rb !md"]],
    [[--ignore-case -g '!*.lua' -g '!*.rb' -g '!*.md' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -e !lua -e !rb -e !md"]],
    [[--ignore-case -g '!*.lua' -g '!*.rb' -g '!*.md' -- 'require']]
  )
end
T["build"]["default opts"]["extension"]["should include and exclude extensions"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -e md !lua"]],
    [[--ignore-case -g '*.md' -g '!*.lua' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -e md -e !lua"]],
    [[--ignore-case -g '*.md' -g '!*.lua' -- 'require']]
  )
end

T["build"]["default opts"]["directory"] = MiniTest.new_set()
T["build"]["default opts"]["directory"]["should include dirs"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -d plugins"]],
    [[--ignore-case -g '**/plugins/**' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -d plugins feature_*"]],
    [[--ignore-case -g '**/plugins/**' -g '**/feature_*/**' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -d plugins -d feature_*"]],
    [[--ignore-case -g '**/plugins/**' -g '**/feature_*/**' -- 'require']]
  )
end
T["build"]["default opts"]["directory"]["should exclude dirs"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -d !plugins"]],
    [[--ignore-case -g '!**/plugins/**' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -d !plugins !feature_*"]],
    [[--ignore-case -g '!**/plugins/**' -g '!**/feature_*/**' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -d !plugins -d !feature_*"]],
    [[--ignore-case -g '!**/plugins/**' -g '!**/feature_*/**' -- 'require']]
  )
end
T["build"]["default opts"]["directory"]["should include and exclude dirs"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -d plugins !feature_*"]],
    [[--ignore-case -g '**/plugins/**' -g '!**/feature_*/**' -- 'require']]
  )
  expect.equality(
    child.lua [[ return M.build "require -- -d plugins -d !feature_*"]],
    [[--ignore-case -g '**/plugins/**' -g '!**/feature_*/**' -- 'require']]
  )
end

T["pending prompts"] = function()
  expect.equality(
    child.lua [[ return M.build(nil)]],
    [[--ignore-case -- '']]
  )
  expect.equality(
    child.lua [[ return M.build ""]],
    [[--ignore-case -- '']]
  )
  expect.equality(
    child.lua [[ return M.build "require"]],
    [[--ignore-case -- '']]
  )
  expect.equality(
    child.lua [[ return M.build "require -"]],
    [[--ignore-case -- '']]
  )
  expect.equality(
    child.lua [[ return M.build "require --"]],
    [[--ignore-case -- 'require']]
  )
end
T["kitchen sink"] = function()
  expect.equality(
    child.lua [[ return M.build "require -- -e rb md !lua -d plugins !feature_* -f !*.test.* *_spec.rb"]],
    [[--ignore-case -g '*_spec.rb' -g '*.rb' -g '*.md' -g '**/plugins/**' -g '!*.test.*' -g '!*.lua' -g '!**/feature_*/**' -- 'require']]
  )
end

return T
