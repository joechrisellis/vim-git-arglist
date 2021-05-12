" Git helpers for modifying the arglist.
" Last Change: 2021 May 12
" Maintainer: Joe Ellis <joechrisellis@gmail.com>

if exists("g:loaded_git_arglist")
  finish
endif
let g:loaded_git_arglist = 1

function! s:InGitRepo()
  call system("git rev-parse HEAD >/dev/null 2>&1")
  return v:shell_error == 0
endfunction

let g:diff_tree_git_flags = "-m --no-commit-id --name-only --diff-filter d -r"
function! s:SetArglistToTreeish(arglist_cmd, treeish, pathspec)
  if !s:InGitRepo()
    echohl ErrorMsg | echo "Not in a git repo!" | echohl None
    return
  endif

  let l:arglist = systemlist(
        \ "git diff-tree "
        \ . g:diff_tree_git_flags . " "
        \ . "'" . a:treeish . "' "
        \ . "-- "
        \ . join(a:pathspec, " "))

  exe a:arglist_cmd . " " . join(l:arglist, " ")
endfunction

let g:diff_git_flags = "--name-only --diff-filter d"
function! s:SetArglistToDiff(arglist_cmd, pathspec)
  if !s:InGitRepo()
    echohl ErrorMsg | echo "Not in a git repo!" | echohl None
    return
  endif

  let l:arglist = systemlist(
        \ "git diff "
        \ . g:diff_git_flags . " "
        \ . "-- "
        \ . join(a:pathspec, " "))

  exe a:arglist_cmd . " " . join(l:arglist, " ")
endfunction

let g:stage_git_flags = "--cached --name-only --diff-filter d"
function! s:SetArglistToStage(arglist_cmd, pathspec)
  if !s:InGitRepo()
    echohl ErrorMsg | echo "Not in a git repo!" | echohl None
    return
  endif

  let l:arglist = systemlist(
        \ "git diff "
        \ . g:stage_git_flags . " "
        \ . "-- "
        \ . join(a:pathspec, " "))

  exe a:arglist_cmd . " " . join(l:arglist, " ")
endfunction

function! s:ArgsTreeish(...)
  let l:treeish = get(a:, 1, "HEAD")
  let l:pathspec = a:000[1:]
  let l:arglist_cmd = "args"
  call s:SetArglistToTreeish(l:arglist_cmd, l:treeish, l:pathspec)
endfunction

function! s:ArglTreeish(...)
  let l:treeish = get(a:, 1, "HEAD")
  let l:pathspec = a:000[1:]
  let l:arglist_cmd = "argl"
  call s:SetArglistToTreeish(l:arglist_cmd, l:treeish, l:pathspec)
endfunction

function! s:ArgsDiff(...)
  let l:pathspec = a:000
  let l:arglist_cmd = "args"
  call s:SetArglistToDiff(l:arglist_cmd, l:pathspec)
endfunction

function! s:ArglDiff(...)
  let l:pathspec = a:000
  let l:arglist_cmd = "argl"
  call s:SetArglistToDiff(l:arglist_cmd, l:pathspec)
endfunction

function! s:ArgsStage(...)
  let l:pathspec = a:000
  let l:arglist_cmd = "args"
  call s:SetArglistToStage(l:arglist_cmd, l:pathspec)
endfunction

function! s:ArglStage(...)
  let l:pathspec = a:000
  let l:arglist_cmd = "argl"
  call s:SetArglistToStage(l:arglist_cmd, l:pathspec)
endfunction

function! s:CompleteGitBranch(A, L, P)
  let l:branches = systemlist(
        \ "git branch -a"
        \ . " | sed 's/^\*/ /'"
        \ . " | awk '{print $1}'")
  call filter(l:branches, "v:val =~ a:A")
  call map(l:branches, "substitute(v:val, '^remotes/', '', '')")
  return l:branches
endfunction

function! s:CompleteArgxTreeish(A, L, P)
  let l:num_spaces = count(substitute(a:L, " \\{2,\\}", " ", "g"), " ")
  if l:num_spaces <= 1
    " Branch completion for the first argument.
    return s:CompleteGitBranch(a:A, a:L, a:P)
  else
    " File completion for the other arguments.
    return getcompletion(a:A, "file")
  endif
endfunction

if !exists(":ArgsTreeish")
  command! -nargs=* -complete=customlist,s:CompleteArgxTreeish ArgsTreeish :call s:ArgsTreeish(<f-args>)
endif
if !exists(":ArglTreeish")
  command! -nargs=* -complete=customlist,s:CompleteArgxTreeish ArglTreeish :call s:ArglTreeish(<f-args>)
endif

if !exists(":ArgsDiff")
  command! -nargs=* -complete=file ArgsDiff :call s:ArgsDiff(<f-args>)
endif
if !exists(":ArglDiff")
  command! -nargs=* -complete=file ArglDiff :call s:ArglDiff(<f-args>)
endif

if !exists(":ArgsStage")
  command! -nargs=* -complete=file ArgsStage :call s:ArgsStage(<f-args>)
endif
if !exists(":ArglStage")
  command! -nargs=* -complete=file ArglStage :call s:ArglStage(<f-args>)
endif
