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
Plug 'doums/darcula'
Plug 'christoomey/vim-tmux-navigator'
Plug 'jiangmiao/auto-pairs'
if has('nvim')
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
endif

call plug#end()
"
syntax on

" color schemes
set termguicolors
colorscheme darcula

" ---------------------------------------------------------------------
" Exact colors extracted from IntelliJ's "Dark" editor color scheme
" (Preferences > Editor > Color Scheme > Export ~/Dark.icls), so nvim
" syntax highlighting matches IntelliJ pixel-for-pixel where possible.
" darcula.vim only defines legacy TS* groups, not the newer @-prefixed
" treesitter captures, so those need explicit overrides below.
" ---------------------------------------------------------------------
hi Normal      guibg=#1E1F22 guifg=#BCBEC4
hi CursorLine  guibg=#26282E
hi LineNr      guifg=#4B5059
hi CursorLineNr guifg=#A1A3AB

hi! link @comment Comment
hi Comment guifg=#7A7E85
hi @comment.documentation guifg=#5F826B gui=italic

hi @string      guifg=#6AAB73
hi @string.escape guifg=#6AAB73
hi @number      guifg=#2AACB8
hi @number.float guifg=#2AACB8

hi @keyword           guifg=#CF8E6D
hi @keyword.type      guifg=#CF8E6D
hi @keyword.modifier  guifg=#CF8E6D
hi @keyword.return    guifg=#CF8E6D
hi @keyword.operator  guifg=#CF8E6D
hi @keyword.conditional guifg=#CF8E6D
hi @keyword.repeat    guifg=#CF8E6D
hi @keyword.import    guifg=#CF8E6D
hi @keyword.exception guifg=#CF8E6D

" class/interface/enum references render as plain foreground in IntelliJ
hi @type         guifg=#BCBEC4
hi @type.builtin guifg=#CF8E6D

" instance & static fields (purple)
hi @variable.member guifg=#C77DBB
" SCREAMING_CASE constants
hi @constant         guifg=#C77DBB gui=italic
" null is a keyword in IntelliJ's scheme (orange), not a purple constant
hi @constant.builtin guifg=#CF8E6D

" method/function declarations & calls (blue)
hi @function            guifg=#57AAF7
hi @function.method     guifg=#57AAF7
hi @function.method.call guifg=#57AAF7
hi @function.builtin    guifg=#57AAF7

" annotations
hi @attribute guifg=#B3AE60

" punctuation/operators match plain foreground, same as IntelliJ
hi @punctuation.bracket   guifg=#BCBEC4
hi @punctuation.delimiter guifg=#BCBEC4
hi @operator              guifg=#BCBEC4

" generic type parameters (e.g. <T>) get IntelliJ's teal
hi @type.parameter guifg=#16BAAC

" coc.nvim semantic tokens (from coc-java/jdtls) give true semantic
" accuracy (e.g. distinguishing generics from real class names) beyond
" what treesitter's syntax-only captures can do; mirror the same colors.
hi CocSemClass         guifg=#BCBEC4
hi CocSemType          guifg=#BCBEC4
hi CocSemInterface     guifg=#BCBEC4
hi CocSemEnum          guifg=#BCBEC4
hi CocSemTypeParameter guifg=#16BAAC
hi CocSemVariable      guifg=#C77DBB
hi CocSemProperty      guifg=#C77DBB
hi CocSemEnumMember    guifg=#C77DBB
hi CocSemMethod        guifg=#57AAF7
hi CocSemFunction      guifg=#57AAF7
hi CocSemKeyword       guifg=#CF8E6D
hi CocSemString        guifg=#6AAB73
hi CocSemNumber        guifg=#2AACB8
hi CocSemComment       guifg=#7A7E85
hi CocSemDecorator     guifg=#B3AE60

" treesitter (Neovim only — plain Vim has no lua/treesitter support)
if has('nvim')
lua <<EOF
require('nvim-treesitter').install { 'c', 'cpp', 'java' }
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'cpp', 'java' },
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


