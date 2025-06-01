# rg-glob-builder.nvim

A Neovim plugin to generate intuitive glob patterns for searching with `rg`.

## Intro

When searching globally with a picker plugin, it can often be helpful to refine your search as you see the results. 

Thankfully, all three of the most popular picker plugins support passing arguments to `rg` in a live-search:

- [The Telescope live grep args extension](https://github.com/nvim-telescope/telescope-live-grep-args.nvim)
- [Native support in `snacks`](https://github.com/folke/snacks.nvim/discussions/461#discussioncomment-11894765)
- [Native support in `fzf-lua`](https://github.com/ibhagwan/fzf-lua/wiki#how-can-i-restrict-grep-search-to-certain-files)

However, native `rg` arguments are clunky to type and difficult to order [correctly](https://github.com/ElanMedoff/rg-glob-builder.nvim#ordering-rg-flags-to-search-intuitively). So I built `rg-glob-builder.nvim`: a plugin to generate a reliable `rg` command with intuitive flag orderings using a handful of ergonomic custom flags.

#### Searching by extension
```bash
~require~ -e rb !md
# --ignore-case --glob '{*.rb}' --glob !'{*.md}' -- 'require'
# prefixes the extension with `*.`
```

#### Searching by file
```bash
~require~ -f init.lua
# --ignore-case --glob '{init.lua}' -- 'require'
```

#### Searching in a directory
```bash
~require~ -d plugins
# --ignore-case --glob '{**/plugins/**}' -- 'require'
```

#### Multiple of the same flag is supported
```bash
~require~ -e rb -f init.lua -e lua
# --ignore-case --glob '{init.lua,*.rb,*.lua}' -- 'require'
```

#### Case-sensitive and whole-word searching
```bash
~require~ -c -w
# --case-sensitive --word-rexegp -- 'require'
```

with later flags overriding earlier ones:
```bash
~require~ -c -w -nc -nw
# --ignore-case -- 'require'
# Searching by partial-word is the default, no flag necessary
```

#### Globs are passed along
```bash
~require~ -d plugin* -f !*.test.*
# --ignore-case --glob '{**/plugin*/**}' --glob !'{*.test.*}' -- 'require'
```

## Setup

If an option is passed to `setup`, it will be inherited by `build`, `fzf_lua_adapter`, and `telescope_adapter`. If an option is passed to both `setup` and directly to `build`, `fzf_lua_adapter`, or `telescope_adapter`, the latter will take precedence.

```lua
-- Default options, no need to pass these to `setup`
require "rg-glob-builder".setup {
  custom_flags = {
    -- The flag to include or negate a directory to the glob pattern. Extensions are 
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
  -- Return `nil` unless the final character is a trailing space. When updating the flags, 
  -- this option will maintain the current search results until the update is complete
  nil_unless_trailing_space = false,
  -- The single-char string to act as the delimiter for the pattern to pass to rg
  pattern_delimiter = "~",
  -- Quote the rg pattern and glob flags in single quotes. Defaults to true, except for in 
  -- the `fzf_lua_adapter`
  auto_quote = true
}
```

## Types 
```lua
--- @class RgGlobBuilderSetupOpts
--- @field pattern_delimiter? string
--- @field custom_flags? RgPatternBuilderSetupOptsCustomFlags
--- @field nil_unless_trailing_space? boolean
--- @field auto_quote? boolean

--- @class RgPatternBuilderSetupOptsCustomFlags
--- @field extension? string
--- @field file? string
--- @field directory? string
--- @field case_sensitive? string
--- @field ignore_case? string
--- @field whole_word? string
--- @field partial_word? string

--- @class FzfLuaAdapterOpts
--- @field fzf_lua_opts table
--- @field rg_glob_builder_opts RgGlobBuilderSetupOpts

--- @class TelescopeAdapterOpts
--- @field telescope_opts table
--- @field rg_glob_builder_opts RgGlobBuilderSetupOpts

--- @class RgGlobBuilderBuildOpts: RgGlobBuilderSetupOpts
--- @field prompt string
```

## Exports

### `build`
```lua
-- RgGlobBuilderBuildOpts
require "rg-glob-builder".build {
  prompt = "" -- The primary pattern to search
  -- ... RgGlobBuilderSetupOpts
}
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

## Ordering `rg` flags to search intuitively

In `rg`, you can think of each `--glob` flag as representing a list of files to include or exclude. 

If two `--glob` flags, each including a set of files, are passed to `rg`, the files from each flag are combined together in the results. This effectively means that the files of the two flags are OR'd:

```bash
rg --ignore-case --glob '*.rb' --glob '*.md' -- 'require'
# Search for `require` in files matching `*.rb` OR in files matching `*.md`
```

> Using `{}` is a simple way to combine multiple `--glob` flags into one:
> ```bash
> rg --ignore-case --glob '*.rb' --glob '*.md' -- 'require'
> ```
> is equivalent to:
> ```bash
> rg --ignore-case --glob '{*.rb,*.md}' -- 'require'
> ```

Similarly, if two `--glob` flags, each excluding a set of files, are passed to `rg`, the files from each flag are combined together and subtracted from the list of results - also an OR:

```bash
rg --ignore-case --glob !'*.rb' --glob !'*.md' -- 'require'
# Search for `require` in files not matching `*.rb` OR in files not matching `*.md`
```

I find this behavior intuitive, and it matches the behavior of VSCode's global search interface as well. The tricky part is including and excluding files in the same command.

For example, in the VSCode global search interface, say we enter the following input:

```
[files to include] README.md
[files to exclude] *.md
```

The behavior of VSCode is that `README.md` does not show up in the list of results. This behavior is effectively an AND of the results from the include search, and the (total results minus the results of the exclude search). How can we achieve the same with `rg`?

According to the `rg` man page:

> If multiple globs match a file or directory, the glob given later in the command line takes precedence.

This means the following command will match VSCode and not show `README.md`:

```bash
rg --ignore-case --glob 'README.md' --glob !'*.md' -- 'require'
```

While the following command will!

```bash
rg --ignore-case --glob '*.md' --glob !'README.md' -- 'require'
```

Stated another way, placing all the exclude `--glob` flags at the end of the `rg` command ensures that we have the same AND/OR behavior as VSCode: (results from the include flags) AND (total results minus the results from the exclude flags).

See this [github issue](https://github.com/BurntSushi/ripgrep/issues/809#issuecomment-366366982) for more details on ordering `rg` flags.

## TODO
- [ ] Adapter for snacks
