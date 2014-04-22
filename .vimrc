set tags=tags;/

"source ~/.vim/plugin/autotag.vim
"source ~/.vim/plugin/taglist.vim


let Tlist_Ctags_Cmd = "/usr/bin/ctags"
let Tlist_WinWidth = 40
map <F4> :TlistToggle<cr>

set tabstop=4
set expandtab
set shiftwidth=4
set softtabstop=4
set backspace=2

autocmd FileType make setlocal noexpandtab

set autoindent

set hlsearch

autocmd BufNewFile,BufRead *.tex set spell
autocmd BufNewFile,BufRead *.tex set tw=78

syntax on
