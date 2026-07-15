" Minimal sane vim config.
" Keep this small — most of vim's defaults are fine.

" --- Basic editor settings --------------------------------------------------
set nocompatible
filetype plugin indent on
syntax enable

" --- Whitespace -------------------------------------------------------------
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
" Show invisible chars (tabs, trailing spaces, NBSP)
set list
set listchars=tab:→\ ,trail:·,nbsp:␣

" --- Display ----------------------------------------------------------------
set number
set relativenumber
set cursorline
set colorcolumn=100
set signcolumn=yes
set scrolloff=8
set sidescrolloff=8
set wrap
" Soft wrap long lines visually, don't break actual content
set linebreak
set breakindent
set showbreak=↪

" --- Search -----------------------------------------------------------------
set hlsearch
set incsearch
set ignorecase
set smartcase

" --- Backups / undo ---------------------------------------------------------
" Don't litter the filesystem; keep one undo file per file in ~/.vim/undo.
set undofile
set undolevels=1000
set undoreload=10000
set backup
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set viminfo+=n~/.vim/viminfo

" --- Misc -------------------------------------------------------------------
set encoding=utf-8
set fileencoding=utf-8
set showmode
set showcmd
set wildmenu
set laststatus=2
set confirm

" --- Leader key -------------------------------------------------------------
let mapleader = ","
let maplocalleader = ","

" --- Key bindings -----------------------------------------------------------
" Quick save
nnoremap <Leader>w :write<CR>
" Clear search highlight
nnoremap <Leader><Space> :nohlsearch<CR>
" Move lines up/down in normal/visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
nnoremap <silent> <Leader>ed :e $MYVIMRC<CR>
" Yank to system clipboard if available
if has('clipboard')
  set clipboard=unnamedplus
endif

" --- Plugin manager (vim-plug, optional — comment out if not used) ---------
" let plug_dir = '~/.vim/plugged'
" call plug#begin(plug_dir)
" Plug 'tpope/vim-surround'
" Plug 'tpope/vim-fugitive'
" Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
" Plug 'junegunn/fzf.vim'
" call plug#end()

" --- Color scheme -----------------------------------------------------------
" Default to a sane built-in if no plugin is installed.
set background=dark
colorscheme default