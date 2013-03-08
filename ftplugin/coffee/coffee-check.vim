" Base on jslint.vim by Jesse Hallett
" https://github.com/hallettj/jslint.vim

if exists("b:did_coffeecheck_plugin")
    finish
else
    let b:did_coffeecheck_plugin = 1
endif

let s:install_dir = expand('<sfile>:p:h')
let s:plugin_path = s:install_dir . "/coffee-check/"
let s:cmd = "cd " . s:plugin_path . " && ./coffee-check"

" au InsertLeave <buffer> call s:CoffeeCheck()
au BufWritePost <buffer> call s:CoffeeCheck()

if !exists("g:coffeeCheckHighlightErrorLine")
  let g:coffeeCheckHighlightErrorLine = 0
endif

if !exists("g:coffeeCheckSignErrorLine")
  let g:coffeeCheckSignErrorLine = 1
endif

function! s:CoffeeCheckClear()
  " Delete previous matches
  let s:matches = getmatches()
  for s:matchId in s:matches
    if s:matchId['group'] == 'CoffeeScriptCompileError'
      call matchdelete(s:matchId['id'])
    endif
  endfor
  " let b:matched = []
  " let b:matchedlines = {}
  let b:cleared = 1
endfunction

function! s:CoffeeCheck()
  let lines = join(getline(1, '$'), "\n")
  if len(lines) == 0
    return
  endif

  highlight link CoffeeScriptCompileError SpellBad

  if exists("b:cleared")
    if b:cleared == 0
      call s:CoffeeCheckClear()
    endif
    let b:cleared = 1
  endif

  let b:qf_list = []
  let b:qf_window_count = -1
  let b:has_errors = 0

  let b:coffee_output = system(s:cmd, lines)

  let l:error_lines = []

  for error in split(b:coffee_output, "\n")
    let b:parts = matchlist(error, '\v(\d+):(.*)')
    if !empty(b:parts)
      let l:line = b:parts[1]
      let b:has_errors = 1
      if g:coffeeCheckHighlightErrorLine == 1
        let s:mID = matchadd('CoffeeScriptCompileError', '\v%' . b:parts[1] . 'l\S.*(\S|$)')
      endif
      if g:coffeeCheckSignErrorLine == 1
        call extend(l:error_lines, [l:line])
      endif

      let l:qf_item = {}
      let l:qf_item.bufnr = bufnr('%')
      let l:qf_item.filename = expand('%')
      let l:qf_item.lnum = b:parts[1]
      let l:qf_item.text = b:parts[2]
      let l:qf_item.type = 'E'
      call add(b:qf_list, l:qf_item)
    endif
  endfor

  if g:coffeeCheckSignErrorLine == 1
    let file_name = s:current_file()
    call s:signInit()
    call s:clear_signs(file_name)
    call s:find_other_signs(file_name)
    call s:show_signs(file_name, l:error_lines)
  endif

  if exists("s:coffeecheck_qf")
    " if jslint quickfix window is already created, reuse it
    call s:ActivateCoffeeCheckQuickFixWindow()
    call setqflist(b:qf_list, 'r')
  else
    " one jslint quickfix window for all buffers
    call setqflist(b:qf_list, '')
    let s:coffeecheck_qf = s:GetQuickFixStackCount()
  endif

  if b:has_errors == 0
    " echo "CoffeeCheck: All good."
  endif
  let b:cleared = 0

  cwindow

endfunction

if !exists("*s:GetQuickFixStackCount")
  function s:GetQuickFixStackCount()
    let l:stack_count = 0
    try
      silent colder 9
    catch /E380:/
    endtry

    try
      for i in range(9)
        silent cnewer
        let l:stack_count = l:stack_count + 1
      endfor
    catch /E381:/
      return l:stack_count
    endtry
  endfunction
endif

if !exists("*s:ActivateCoffeeCheckQuickFixWindow")
  function s:ActivateCoffeeCheckQuickFixWindow()
    try
      silent colder 9 " go to the bottom of quickfix stack
    catch /E380:/
      endtry

    if s:coffeecheck_qf > 0
      try
        exe "silent cnewer " . s:coffeecheck_qf
      catch /E381:/
        echoerr "Could not activate CoffeeCheck Quickfix Window."
      endtry
    endif
  endfunction
endif


" Sign functions from gitgutter
" https://github.com/airblade/vim-gitgutter/blob/master/plugin/gitgutter.vim

function! s:signInit()
  if !exists('g:coffee_check_sign_initialised')

    highlight errorSign         guifg=#990000 guibg=NONE ctermfg=9 ctermbg=NONE
    sign define coffeeCheckErrorSign text=!  texthl=errorSign    linehl=NONE

    " Vim doesn't namespace sign ids so every plugin shares the same
    " namespace.  Sign ids are simply integers so to avoid clashes with other
    " signs we guess at a clear run.
    "
    " Note also we currently never reset s:next_sign_id.
    let s:first_sign_id = 5000
    let s:next_sign_id = s:first_sign_id
    let s:sign_ids = {}  " key: filename, value: list of sign ids
    let s:other_signs = []

    let g:coffee_check_sign_initialised = 1
  endif
endfunction

function! s:current_file()
  return expand("%:p")
endfunction

" Sign processing {{{

function! s:clear_signs(file_name)
  if exists('s:sign_ids') && has_key(s:sign_ids, a:file_name)
    for id in s:sign_ids[a:file_name]
      exe ":sign unplace " . id . " file=" . a:file_name
    endfor
    let s:sign_ids[a:file_name] = []
  endif
endfunction

" This assumes there are no GitGutter signs in the current file.
" If this is untenable we could change the regexp to exclude GitGutter's
" signs.
function! s:find_other_signs(file_name)
  redir => signs
  silent exe ":sign place file=" . a:file_name
  redir END
  let s:other_signs = []
  for sign_line in split(signs, '\n')
    if sign_line =~ '^\s\+line'
      let matches = matchlist(sign_line, '^\s\+line=\(\d\+\)')
      let line_number = str2nr(matches[1])
      call add(s:other_signs, line_number)
    endif
  endfor
endfunction

function! s:show_signs(file_name, modified_lines)
  for line in a:modified_lines
    let line_number = line[0]
    let name = 'coffeeCheckErrorSign'
    call s:add_sign(line_number, name, a:file_name)
  endfor
endfunction

function! s:add_sign(line_number, name, file_name)
  let id = s:next_sign_id()
  if !s:is_other_sign(a:line_number)  " Don't clobber other people's signs.
    exe ":sign place " . id . " line=" . a:line_number . " name=" . a:name . " file=" . a:file_name
    call s:remember_sign(id, a:file_name)
  endif
endfunction

function! s:next_sign_id()
  let next_id = s:next_sign_id
  let s:next_sign_id += 1
  return next_id
endfunction

function! s:remember_sign(id, file_name)
  if has_key(s:sign_ids, a:file_name)
    let sign_ids_for_current_file = s:sign_ids[a:file_name]
    call add(sign_ids_for_current_file, a:id)
  else
    let sign_ids_for_current_file = [a:id]
  endif
  let s:sign_ids[a:file_name] = sign_ids_for_current_file
endfunction

function! s:is_other_sign(line_number)
  return index(s:other_signs, a:line_number) == -1 ? 0 : 1
endfunction
