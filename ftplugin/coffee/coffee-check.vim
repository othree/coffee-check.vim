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

au InsertLeave <buffer> call s:CoffeeCheck()
au BufWritePost <buffer> call s:CoffeeCheck()

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

  let b:coffee_output = system(s:cmd, lines)

  echom b:coffee_output
  for error in split(b:coffee_output, "\n")
    let b:parts = matchlist(error, '\v(\d+):(.*)')
    if !empty(b:parts)

      let s:mID = matchadd('CoffeeScriptCompileError', '\v%' . b:parts[1] . 'l\S.*(\S|$)')

      let l:qf_item = {}
      let l:qf_item.bufnr = bufnr('%')
      let l:qf_item.filename = expand('%')
      let l:qf_item.lnum = b:parts[1]
      let l:qf_item.text = b:parts[2]
      let l:qf_item.type = 'E'
      call add(b:qf_list, l:qf_item)
    endif
  endfor

  if exists("s:coffeecheck_qf")
    " if jslint quickfix window is already created, reuse it
    call s:ActivateCoffeeCheckQuickFixWindow()
    call setqflist(b:qf_list, 'r')
  else
    " one jslint quickfix window for all buffers
    call setqflist(b:qf_list, '')
    let s:coffeecheck_qf = s:GetQuickFixStackCount()
  endif
  let b:cleared = 1
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
