" Git helpers for modifying the arglist.
" Last Change: 2021 May 18
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

let g:treeish_git_flags = "-m --no-commit-id --name-only --diff-filter d -r"
function! g:TreeishFiles(...)
  let l:treeish = get(a:, 1, "HEAD")
  let l:pathspec = a:000[1:]
  return s:Git(
        \ "diff-tree "
        \ . g:treeish_git_flags . " "
        \ . "'" . l:treeish . "' "
        \ . "-- "
        \ . join(l:pathspec, " "))
endfunction

let g:diffed_git_flags = "--name-only --diff-filter d"
function! g:DiffedFiles(...)
  let l:gitrevision = get(a:, 1, "")
  let l:pathspec = a:000[1:]
  return s:Git(
        \ "diff "
        \ . g:diffed_git_flags . " "
        \ . l:gitrevision . " "
        \ . "-- "
        \ . join(l:pathspec, " "))
endfunction

let g:untracked_git_flags = "--full-name --others --exclude-standard"
function! g:UntrackedFiles(...)
  return s:Git(
        \ "ls-files "
        \ . g:untracked_git_flags . " "
        \ . "-- "
        \ . join(a:000, " "))
endfunction

let g:staged_git_flags = "--cached --name-only --diff-filter d"
function! g:StagedFiles(...)
  return s:Git(
        \ "diff "
        \ . g:staged_git_flags . " "
        \ . "-- "
        \ . join(a:000, " "))
endfunction

let g:conflicted_git_flags = "--name-only --diff-filter U"
function! g:ConflictedFiles(...)
  return s:Git(
        \ "diff "
        \ . g:conflicted_git_flags . " "
        \ . "-- "
        \ . join(a:000, " "))
endfunction

function! s:CommandWrapper(...)
  if !s:InGitRepo()
    echohl ErrorMsg | echo "Not in a git repo!" | echohl None
    return
  endif

  let l:ContextFunction = a:1
  let l:arglist_cmd = a:2
  let l:bang = a:3
  let l:args = a:000[3:]
  if l:bang
    let l:arglist_cmd .= "!"
  endif

  let l:files = []
  try
    let l:files = call(l:ContextFunction, l:args)
  catch /.*/
    echohl ErrorMsg | echo "Caught error: " . v:exception | echohl None
  endtry

  if !empty(l:files)
    exe l:arglist_cmd . " " . join(l:files, " ")
  else
    echohl WarningMsg | echo "No files found." | echohl None
  endif
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

function! s:CompleteRefThenPath(A, L, P)
  let l:num_spaces = count(substitute(a:L, " \\{2,\\}", " ", "g"), " ")
  if l:num_spaces <= 1
    " Branch completion for the first argument.
    return s:CompleteGitBranch(a:A, a:L, a:P)
  else
    " File completion for the other arguments.
    return getcompletion(a:A, "file")
  endif
endfunction

let s:context_dict = {
      \ "Treeish" : ["-nargs=*", "-complete=customlist,s:CompleteRefThenPath"],
      \ "Diffed" : ["-nargs=*", "-complete=customlist,s:CompleteRefThenPath"],
      \ "Untracked" : ["-nargs=*", "-complete=file"],
      \ "Staged" : ["-nargs=*", "-complete=file"],
      \ "Conflicted" : ["-nargs=*", "-complete=file"],
      \ }

let s:args_cmd_dict = {
      \ "Args" : ["-bang"],
      \ "Argl" : ["-bang"],
      \ "ArgAdd" : [],
      \ "ArgDelete" : [],
      \ "ArgEdit" : ["-bang"],
      \ }

for s:args_cmd_dict_entry in items(s:args_cmd_dict)
  let s:prefix = s:args_cmd_dict_entry[0]
  let s:flags_a = s:args_cmd_dict_entry[1]

  for s:context_dict_entry in items(s:context_dict)
    let s:context = s:context_dict_entry[0]
    let s:flags_b = s:context_dict_entry[1]

    let s:cmd = s:prefix . s:context
    let s:flags = join(s:flags_a + s:flags_b, " ")
    exe "command! " . s:flags . " " . s:cmd . " :call s:CommandWrapper('g:" . s:context . "Files', '" . tolower(s:prefix) . "', <bang>0, <f-args>)"
  endfor
endfor
