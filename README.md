# rg-glob-builder.nvim

A Neovim plugin to generate intuitive glob patterns for searching with `rg`.

## Intro

When searching globally with a picker plugin, it can often be helpful to refine your search as you see the results. 

Thankfully, all three of the most popular picker plugins support passing arguments to `rg` in a live-search:

- [The Telescope live grep args extension](https://github.com/nvim-telescope/telescope-live-grep-args.nvim)
- [Native support in `snacks`](https://github.com/folke/snacks.nvim/discussions/461#discussioncomment-11894765)
- [Native support in `fzf-lua`](https://github.com/ibhagwan/fzf-lua/wiki#how-can-i-restrict-grep-search-to-certain-files)

However, native `rg` arguments are clunky to type and difficult to order [correctly](https://github.com/ElanMedoff/rg-glob-builder.nvim#understanding-rg-glob-flags). So I built `rg-glob-builder.nvim`: a plugin to generate a reliable `rg` command with intuitive flag orderings using a handful of ergonomic custom flags.

> Note: the following examples use the `build` function, which is the most straightforward way to generate `rg` flags with `rg-glob-builder`. In practice, I'd recommend using the `fzf_lua_adapter` or `telescope_adapter`, depending on your picker plugin.

#### Searching by extension
```lua
require "rg-glob-builder".build "require -- -e rb !md"
-- returns: "--ignore-case -g '*.rb' -g !'*.md' -- 'require'"
-- transforms extensions as `*.[extension]`
```

#### Searching by file
```lua
require "rg-glob-builder".build "require -- -f init.lua"
-- returns: "--ignore-case -g 'init.lua' -- 'require'"
```

#### Searching in a directory
```lua
require "rg-glob-builder".build "require -- -d plugins"
-- returns: "--ignore-case -g '**/plugins/**' -- 'require'"
-- transforms directories as `**/[directory]/**`
```

#### Multiple of the same flag is supported
```lua
require "rg-glob-builder".build "require -- -e rb -f init.lua -e lua"
-- returns: "--ignore-case -g 'init.lua' -g '*.rb' -g '*.lua' -- 'require'"
```

#### Case-sensitive and whole-word searching
```lua
require "rg-glob-builder".build "require -- -c -w"
-- returns: "--case-sensitive --word-rexegp -- 'require'"
```

with later flags overriding earlier ones:
```lua
require "rg-glob-builder".build "require -- -c -w -nc -nw"
-- returns: "--ignore-case -- 'require'"
-- searching by partial-word is the default, no flag necessary
```

#### Globs are passed along
```lua
require "rg-glob-builder".build "require -- -d plugin* -f !*.test.*"
-- returns: "--ignore-case -g '**/plugin*/**' -g '!*.test.*' -- 'require'"
```

## Setup

If an option is passed to `setup`, it will be inherited by `build`, `fzf_lua_adapter`, and `telescope_adapter`. If an option is passed to both `setup` and directly to `build`, `fzf_lua_adapter`, or `telescope_adapter`, the latter will take precedence.

```lua
-- Default options, no need to pass these to `setup`
require "rg-glob-builder".setup {
  custom_flags = {
    -- The flag to include or negate a directory to the glob pattern. Directories are 
    -- updated internally to "**/[directory]/**"
    directory = "-d",
    -- The flag to include or negate an extension to the glob pattern. Extensions are 
    -- prefixed internally with "*."
    extension = "-e",
    -- The flag to include or negate a file to the glob pattern. Files are passed without 
    -- modification to the glob
    file = "-f",
    -- The flag to search case sensitively, adds the `--case-sensitive` flag
    case_sensitive = "-c",
    -- The flag to search case insensitively, adds the `--case-ignore` flag
    ignore_case = "-nc",
    -- The flag to search case by whole word, adds the `--word-regexp` flag
    whole_word = "-w",
    -- The flag to search case by partial word, removes the `--word-regexp` flag 
    -- Searching by partial word is the default behavior in rg
    partial_word = "-nw",
  },
  -- Quote the rg pattern and glob flags in single quotes. Defaults to true, except for in 
  -- the `fzf_lua_adapter`
  auto_quote = true
}
```

## Types 
```lua
--- @class RgGlobBuilderOpts
--- @field custom_flags? RgGlobBuilderOptsCustomFlags
--- @field auto_quote? boolean Defualts to `true`

--- @class RgGlobBuilderOptsCustomFlags
--- @field extension? string Defaults to "-e"
--- @field file? string Defaults to "-f"
--- @field directory? string Defaults to "-d"
--- @field case_sensitive? string Defaults to "-c"
--- @field ignore_case? string Defaults to "-nc"
--- @field whole_word? string Defaults to "-w"
--- @field partial_word? string Defaults to "-nw"

--- @class FzfLuaAdapterOpts
--- @field fzf_lua_opts table
--- @field rg_glob_builder_opts RgGlobBuilderOpts

--- @class TelescopeAdapterOpts
--- @field telescope_opts table
--- @field rg_glob_builder_opts RgGlobBuilderOpts
```

## Exports

### `build`
```lua
-- RgGlobBuilderBuildOpts
require "rg-glob-builder".build("[prompt]", {
  -- ... RgGlobBuilderSetupOpts
})
```

### `fzf_lua_adapter`
```lua
-- FzfLuaAdapterOpts
require "rg-glob-builder".fzf_lua_adapter {
  -- Standard fzf-lua options https://github.com/ibhagwan/fzf-lua#customization
  fzf_lua_opts = {}

  -- RgGlobBuilderSetupOpts
  rg_glob_builder_opts = {}
}
```

### `telescope_adapter`
```lua
-- TelescopeAdapterOpts
require "rg-glob-builder".telescope_adapter {
  -- Standard telescope options https://github.com/nvim-telescope/telescope.nvim#customization
  telescope_opts = {}

  -- RgGlobBuilderSetupOpts
  rg_glob_builder_opts = {}
}
```

## Understanding `rg` glob flags

Say we have the following directory:

```
.
├── a
├── b
├── c
└── d
```

In `rg`, each `-g` flag is tested against each file, and if matched, either includes or excludes the file based on the glob.

For example, say we have two `-g` flags, each set to include the files they match.

```bash
$ rg --files-with-matches -g 'a' -g 'b' -- ''
a
b
```

Going through each file:

```
a => matched by -g 'a' => include
b => matched by -g 'b' => include
c => not matched by any glob => exclude
d => not matched by any glob => exclude

=> return: a,b
```

For multiple `-g` flag with a `!`, we can take a similar process:

```bash
$ rg --files-with-matches -g !'a' -g !'b' -- ''
c
d
```

Going through each file:

```
a => matched by -g !'a' => exclude
b => matched by -g !'b' => exclude
c => not matched by any glob => include
d => not matched by any glob => include

=> return: c,d
```

Things get a bit trickier when a file is matched by more than one glob, for example:

```bash
$ rg --files-with-matches -g 'a' -g 'b' -g !'a' -- ''
```

Should this return `a,b` or just `b`? The man pages have an answer:

> If multiple globs match a file or directory, the glob given later in the command line takes precedence.

Using this info, we can go through each file:

```
a => matched by -g 'a' and -g !'a' => last matched by -g !'a' => exclude
b => matched by -g 'b' => include
c => not matched by any glob => exclude
d => not matched by any glob => exclude

=> return: b
```

If we swapped the exclude flag to the begining of the command, we'd get the opposite behavior:

```bash
$ rg --files-with-matches -g !'a' -g 'b' -g 'a' -- ''
```

```
a => matched by -g 'a' and -g !'a' => last matched by -g 'a' => include
b => matched by -g 'b' => include
c => not matched by any glob => exclude
d => not matched by any glob => exclude

=> return: a,b
```

In VSCode, using the global search interface for a similar query would look as follows:

```
[files to include] a,b
[files to exclude] a
```

Interestingly, this VSCode search would return `a`, not `a,b`. In other words, VSCode matches the command `rg --files-with-matches -g 'a' -g 'b' -g !'a' -- ''` - the variant with the exclude at the _end_.

I personally find this result most intuitive as well, which is why `rg-glob-builder` places all exclude flags at the end.

## TODO
- [ ] Adapter for snacks
