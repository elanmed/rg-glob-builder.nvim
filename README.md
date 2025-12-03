# `rg-glob-builder.nvim`

A Neovim plugin to generate intuitive glob patterns for searching with `rg`.

![demo](https://elanmed.dev/nvim-plugins/rg-glob-builder.png)

> See the README files for [fzf](https://github.com/elanmed/rg-glob-builder.nvim/blob/master/README-FZF-LUA.md) and [telescope](https://github.com/elanmed/rg-glob-builder.nvim/blob/master/README-TELESCOPE.md) for examples on how to integrate `rg-glob-builder` with the picker of your choice.

## Intro

When searching globally with a picker plugin, it can often be helpful to refine your search as you see the results.

Thankfully, all three of the most popular picker plugins support passing arguments to `rg` in a live-search:

- [The Telescope live grep args extension](https://github.com/nvim-telescope/telescope-live-grep-args.nvim)
- [Native support in `snacks`](https://github.com/folke/snacks.nvim/discussions/461#discussioncomment-11894765)
- [Native support in `fzf-lua`](https://github.com/ibhagwan/fzf-lua/wiki#how-can-i-restrict-grep-search-to-certain-files)

However, native `rg` arguments are clunky to type and difficult to order [correctly](https://github.com/elanmed/rg-glob-builder.nvim#ordering-rg-glob-flags). So I built `rg-glob-builder.nvim`: a plugin to generate a reliable `rg` command with intuitive flag orderings using a handful of ergonomic custom flags.

#### Searching by extension

```lua
require "rg-glob-builder".build "require -- -e rb !md"
-- returns: "--ignore-case '-g' '*.rb' '-g' !'*.md' -- 'require'"
-- transforms extensions as `*.[extension]`
```

#### Searching by file

```lua
require "rg-glob-builder".build "require -- -f init.lua"
-- returns: "--ignore-case '-g' 'init.lua' -- 'require'"
```

#### Searching in a directory

```lua
require "rg-glob-builder".build "require -- -d plugins"
-- returns: "--ignore-case '-g' '**/plugins/**' -- 'require'"
-- transforms directories as `**/[directory]/**`
```

#### Multiple of the same flag is supported

```lua
require "rg-glob-builder".build "require -- -e rb -f init.lua -e lua"
-- returns: "--ignore-case '-g' 'init.lua' '-g' '*.rb' '-g' '*.lua' -- 'require'"
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
-- returns: "--ignore-case '-g' '**/plugin*/**' '-g' '!*.test.*' -- 'require'"
```

#### Passing raw input

```lua
require "rg-glob-builder".build "require -- -r -g plugin*"
-- returns: "--ignore-case '-g' 'plugin*' -- 'require'"
```

## Exports

```lua
--- @class RgGlobBuilderOpts
--- @field custom_flags? RgGlobBuilderOptsCustomFlags

--- @class RgGlobBuilderOptsCustomFlags
--- @field extension? string Defaults to "-e"
--- @field file? string Defaults to "-f"
--- @field directory? string Defaults to "-d"
--- @field case_sensitive? string Defaults to "-c"
--- @field ignore_case? string Defaults to "-nc"
--- @field whole_word? string Defaults to "-w"
--- @field partial_word? string Defaults to "-nw"

require "rg-glob-builder".build("query", {
  -- Default options, no need to pass these to `build`
  -- RgGlobBuilderOptsCustomFlags
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
    -- The flag to begin passing raw input that is only minimally processed (i.e. escaped)
    raw_input = "-r",
  },
})
```

## Ordering `rg` glob flags

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
