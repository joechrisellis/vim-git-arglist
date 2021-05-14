" Git helpers for modifying the arglist.
" Last Change: 2021 May 12
" Maintainer: Joe Ellis <joechrisellis@gmail.com>

if exists("g:loaded_git_arglist")
  finish
endif
let g:loaded_git_arglist = 1

function! s:Git(git_args)
  let l:result_lines = systemlist("git " . a:git_args)
  if v:shell_error != 0
    throw "Git exited with non-zero exit code."
  endif
  return l:result_lines
endfunction

function! s:InGitRepo()
  call system("git rev-parse HEAD >/dev/null 2>&1")
  return v:shell_error == 0
endfunction

let g:diff_tree_git_flags = "-m --no-commit-id --name-only --diff-filter d -r"
function! s:SetArglistToTreeish(arglist_cmd, treeish, pathspec)
  let l:arglist = s:Git(
        \ "diff-tree "
        \ . g:diff_tree_git_flags . " "
        \ . "'" . a:treeish . "' "
        \ . "-- "
        \ . join(a:pathspec, " "))

  exe a:arglist_cmd . " " . join(l:arglist, " ")
endfunction

let g:diff_git_flags = "--name-only --diff-filter d"
function! s:SetArglistToDiff(arglist_cmd, pathspec)
  let l:arglist = s:Git(
        \ "diff "
        \ . g:diff_git_flags . " "
        \ . "-- "
        \ . join(a:pathspec, " "))

  exe a:arglist_cmd . " " . join(l:arglist, " ")
endfunction

let g:untracked_git_flags = "--others --exclude-standard"
function! s:SetArglistToUntracked(arglist_cmd, pathspec)
  let l:arglist = s:Git(
        \ "ls-files "
        \ . g:untracked_git_flags . " "
        \ . "-- "
        \ . join(a:pathspec, " "))

  exe a:arglist_cmd . " " . join(l:arglist, " ")
endfunction

let g:stage_git_flags = "--cached --name-only --diff-filter d"
function! s:SetArglistToStage(arglist_cmd, pathspec)
  let l:arglist = s:Git(
        \ "diff "
        \ . g:stage_git_flags . " "
        \ . "-- "
        \ . join(a:pathspec, " "))

  exe a:arglist_cmd . " " . join(l:arglist, " ")
endfunction

function! s:Treeish(...)
  let l:arglist_cmd = a:1
  let l:treeish = get(a:, 2, "HEAD")
  let l:pathspec = a:000[2:]

  call s:SetArglistToTreeish(l:arglist_cmd, l:treeish, l:pathspec)
endfunction

function! s:Diff(...)
  let l:arglist_cmd = a:1
  let l:pathspec = a:000[1:]
  call s:SetArglistToDiff(l:arglist_cmd, l:pathspec)
endfunction

function! s:Untracked(...)
  let l:arglist_cmd = a:1
  let l:pathspec = a:000[1:]
  call s:SetArglistToUntracked(l:arglist_cmd, l:pathspec)
endfunction

function! s:Stage(...)
  let l:arglist_cmd = a:1
  let l:pathspec = a:000[1:]
  call s:SetArglistToStage(l:arglist_cmd, l:pathspec)
endfunction

function! s:ErrWrapper(...)
  if !s:InGitRepo()
    echohl ErrorMsg | echo "Not in a git repo!" | echohl None
    return
  endif

  let l:GitFunction = a:1
  let l:args = a:000[1:]
  try
    call call(l:GitFunction, l:args)
  catch /.*/
    echohl ErrorMsg | echo "Caught error: " . v:exception | echohl None
  endtry
endfunction

function! s:CompleteGitBranch(A, L, P)
  try
    let l:branches = s:Git("branch -a")
  catch /.*/
    return []
  endtry

  " The magic below demangles the Git output.
  " Something like this:
  "     * master
  "       remotes/origin/HEAD -> origin/master
  "       remotes/origin/master
  "
  " becomes:
  "     master
  "     origin/HEAD
  "     origin/master
  call map(l:branches, "substitute(v:val, '^*', ' ', '')")
  call map(l:branches, "substitute(v:val, '\\s*\\(\\S\\+\\).*', '\\1', '')")
  call map(l:branches, "substitute(v:val, '^remotes/', '', '')")

  " Then filter by what the user asked for.
  call filter(l:branches, "v:val =~ a:A")
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

function! s:GetCompletion(action)
  if a:action ==# "Treeish"
    return "customlist,s:CompleteArgxTreeish"
  else
    return "file"
  endif
endfunction

for s:args_cmd in ["Args", "Argl", "ArgAdd", "ArgDelete"]
  for s:action in ["Treeish", "Diff", "Untracked", "Stage"]
    let s:new_cmd = s:args_cmd . s:action
    let s:new_cmd_completion = s:GetCompletion(s:action)
    if !exists(":" . s:new_cmd)
      exe "command! -nargs=* -complete=" . s:new_cmd_completion . " " . s:new_cmd . " :call s:ErrWrapper('s:" . s:action . "', '" . tolower(s:args_cmd) . "', <f-args>)"
    endif
  endfor
endfor
