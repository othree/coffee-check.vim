" Base on jslint.vim by Jesse Hallett
" https://github.com/hallettj/jslint.vim

echo "init cc"

if exists("b:did_coffeecheck_plugin")
    finish
else
    let b:did_coffeecheck_plugin = 1
endif

let s:install_dir = expand('<sfile>:p:h')
let s:plugin_path = s:install_dir . "/../../bin/"
let s:cmd = "cd " . s:plugin_path . " && ./coffee-check"

au InsertLeave <buffer> call s:CoffeeCheck()
au BufWritePost <buffer> call s:CoffeeCheck()

function! s:CoffeeCheck()
  let lines = getline(1, '$')
  if len(lines) == 0
      return
  endif
  let b:coffee_output = system(s:cmd, lines)

  echo b:coffee_output
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

if !exists("*s:ActivateJSLintQuickFixWindow")
  function s:ActivateJSLintQuickFixWindow()
    try
      silent colder 9 " go to the bottom of quickfix stack
    catch /E380:/
      endtry

    if s:jslint_qf > 0
      try
        exe "silent cnewer " . s:jslint_qf
      catch /E381:/
        echoerr "Could not activate JSLint Quickfix Window."
      endtry
    endif
  endfunction
endif
