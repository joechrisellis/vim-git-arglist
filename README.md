# vim-git-arglist

A plugin which adds helper commands for modifying the arglist based on the
current Git repository.

Vi/Vim's arglist is useful for grouping together a collection of files for easy
navigation. This plugin adds helper commands that interface with Git for
setting the arglist based on the repository you're working with.

As a quick example, you can add all of the files modified/added by a particular
commit to the arglist with `:ArgsTreeish <commit_hash>`. Or, you can add all of
the files modified/created in your working tree to the arglist using
`:ArgsDiff`. For more, check out `:h git-arglist-example-workflow`, which
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

# License

Copyright (c) Joe Ellis. Distributed under the same terms as Vim itself. See
`:help license`.
