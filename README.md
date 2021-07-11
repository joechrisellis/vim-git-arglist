# vim-git-arglist

A plugin which adds helper commands for manipulating the arglist based on the
current Git repository.

Vi/Vim's arglist is useful for grouping together a collection of files for easy
navigation. This plugin adds helper commands that interface with Git for
manipulating the arglist based on the repository you're working with.

As a quick example, you can add all of the files modified/added by a particular
commit to the arglist with `:ArgsTreeish <commit_hash>`. Or, you can add all of
the files modified/created in your working tree to the arglist using
`:ArgsDiffed`. For more, check out `:h git-arglist-example-workflow`, which
explains one of my personal workflows with this plugin.

You can also use `:h git-arglist` for help.

# Installation

The plugin is plain Vimscript, so the installation doesn't require anything
special. You can install the plugin using whichever plugin manager you normally
use. For example, if you use vim-plug, add:

```
Plug 'joechrisellis/vim-git-arglist'
```

to your vimrc.

# Examples

You can take full advantage of Git pathspecs with vim-git-arglist:

- `:ArgsDiffed HEAD :/'**'.{cpp,h}` -- open all C++ source/header files that
  have changed in the working tree. Strictly, this means "set the arglist to
  all files modified in the working tree with extension `.cpp` and `.h`".
- `:ArgsTreeish <commit> ':**/test/**'` -- open all tests touched by
  `<commit>`. Strictly, this means "set the arglist to all files in the
  repository touched by `<commit>` that are beneath a `test` subdirectory".
- `:ArgsTreeish <commit> ':!/**/docs/**'` -- open everything touched by
  `<commit>` except for documentation changes. Strictly, this means "set the
  arglist to all files in the repository touched by `<commit>` that are not
  beneath a `docs` subdirectory".

You can also take advantage of Git revision specifiers:

- `:ArgsDiffed @{u}` -- open all of the files that have been modified on the
  current branch since the last push to upstream. If you want to exclude
  uncommitted changes in your working directory, you can use
  `:ArgsDiffed ..@{u}`.

# License

Copyright (c) Joe Ellis. Distributed under the same terms as Vim itself. See
`:help license`.
