call plug#begin('~/.vim/plugged')
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-rooter'
Plug 'moll/vim-bbye'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'tomasiser/vim-code-dark'
Plug 'christoomey/vim-tmux-navigator'
Plug 'jiangmiao/auto-pairs'
if has('nvim')
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
endif

call plug#end()
"
" color schemes
set termguicolors
colorscheme codedark

" treesitter (Neovim only — plain Vim has no lua/treesitter support)
if has('nvim')
lua <<EOF
require('nvim-treesitter').install { 'c', 'cpp' }
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'cpp' },
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
EOF
endif

let mapleader = " "
set timeoutlen=500

" tabs to 4 spaces
set tabstop=4
set shiftwidth=4
set expandtab

" line numbers
set number
set relativenumber

" clipboard
set clipboard=unnamed

" code folding
set foldmethod=indent
set nofoldenable

" searching
set hlsearch
set incsearch

" misc
set backspace=indent,eol,start
set splitright
set background=dark
set encoding=utf-8
set nobackup
set nowritebackup
set updatetime=300
set signcolumn=yes

set grepformat^=%f:%l:%c:%m
set grepprg=rg\ --vimgrep\ --smart-case\ --follow\ --no-messages\ --hidden

filetype plugin on

" coc.nvim navigation
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <silent> K :call CocActionAsync('doHover')<CR>
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" NERDTree
let g:NERDTreeShowHidden = 1
nnoremap <leader>n :NERDTreeFind<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>

" window navigation (C-h/j/k/l): handled by vim-tmux-navigator, which also
" forwards to tmux to switch panes when there's no more vim split to move to

" window navigation from terminal mode
tnoremap <C-h> <C-w>h
tnoremap <C-j> <C-w>j
tnoremap <C-k> <C-w>k
tnoremap <C-l> <C-w>l

" tab navigation
nnoremap <leader>1 1gt
nnoremap <leader>2 2gt
nnoremap <leader>3 3gt

nnoremap <leader>o :Files<CR>
nnoremap <leader>f :BLines<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>q :Bdelete<CR>

nnoremap <leader><S-f> :Rg<CR>

nnoremap <leader>t :vert term<CR>
nnoremap <leader>c :vert term claude<CR>

" build (cmake+ninja), errors go to quickfix
set makeprg=cmake\ --build\ build
autocmd QuickFixCmdPost make cwindow
nnoremap <leader>m :make<CR>

" build a target then run it in a terminal split
function! s:BuildAndRun(target)
  execute '!cmake --build build --target ' . a:target
  if v:shell_error == 0
    execute 'vert term ./build/' . a:target
  endif
endfunction
function! s:Targets(...)
  return systemlist('ninja -C build -t targets all | grep EXECUTABLE_LINKER | cut -d: -f1 | grep -v "\[" | sort -u')
endfunction
command! -nargs=1 -complete=customlist,s:Targets Run call s:BuildAndRun(<f-args>)
nnoremap <leader>r :Run

nnoremap <leader>vs :source ~/.vimrc<CR>
nnoremap <esc> :noh<CR>
nnoremap <silent> vv <C-w>v

" comment toggle (Neovim's built-in gc/gcc, terminal sends Ctrl+/ as <C-_>)
" note: must use xmap/nmap, not noremap — gc/gcc are themselves mappings
xmap <C-_> gc
nmap <C-_> gcc


