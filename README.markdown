# coffee-check.vim

## Introduction

It is hard to find out where is you script error if you use [CoffeeScript](http://coffeescript.org/) [plugin](https://github.com/jrburke/require-cs) for [RequireJS](http://requirejs.org/). This Vim plugin is design to help reduce the effect of this issue, it will check the code syntax base on CoffeeScript compiler everytime when you save a coffee file automatically.

## Requirement

* node: used to compile coffee script.

## Installation

Use [pathogen.vim](http://www.vim.org/scripts/script.php?script_id=2332) or [Vundle](https://github.com/gmarik/vundle) is suggestion.

If you didn't install [vim-coffee-script](http://www.vim.org/scripts/script.php?script_id=3590)
Add the following line to vimrc:

    au BufRead,BufNewFile *.coffee set ft=coffee

## Usage

To disable error line sign, add this line to your ~/.vimrc file:

    let g:coffeeCheckSignErrorLine = 0

To enable error highlighting altogether add this line to your ~/.vimrc file:

    let g:coffeeCheckHighlightErrorLine = 1

## Important (Known Issues)

* Only one error appears in every check, if you have several error in your script, you will have to fix one by one.
* Some error message can't locate to correct line number, all this kind of error will mark to line 1.
* Cause of previous issue, can't use the behavior of jslint.vim. So Vim will open quickfix window if any error was found.

## Acknowledge

Thanks for the base of [jslint.vim](https://github.com/hallettj/jslint.vim) by [Jesse Hallett](http://sitr.us/).

## License

Release under MIT License.
