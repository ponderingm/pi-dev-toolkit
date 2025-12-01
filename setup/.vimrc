" -------------------------------------------------------------------------
" Portable & Lightweight Vimrc (Universal)
" -------------------------------------------------------------------------
" 基本思想:
" 1. 外部プラグインなし
" 2. エラーを出さない（古いVim互換）
" 3. 環境を汚さない（UndoファイルやSWAPを作らない）
" 4. どんなターミナルでも視認性を確保する
" -------------------------------------------------------------------------

" --- Basic ---
set nocompatible             " Vi互換OFF
scriptencoding utf-8         " 読み込み時の文字コード
set encoding=utf-8           " 内部文字コード
" 保存時の文字コード (順次トライ)
set fileencodings=utf-8,euc-jp,sjis,cp932,iso-2022-jp

" --- Performance & I/O (Stateless) ---
set ttyfast                  " 高速ターミナル接続を想定
set lazyredraw               " マクロ等の途中経過を描画しない（高速化）
set nobackup                 " バックアップ作成無効
set noswapfile               " スワップファイル作成無効
set noundofile               " Undoファイル作成無効 (一時利用に特化)
set autoread                 " 外部変更の検知

" --- Search ---
set ignorecase               " 大文字小文字を区別しない
set smartcase                " 大文字が入っている場合のみ区別
set incsearch                " インクリメンタルサーチ
set hlsearch                 " 検索結果ハイライト
set wrapscan                 " 最後まで検索したら先頭に戻る

" --- Visual ---
set number                   " 行番号
set showmatch                " 括弧の強調
set list                     " 不可視文字表示
" 文字化けリスクを極限まで下げるためASCII文字のみで構成
set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+

" シンタックスハイライト (機能がある場合のみ有効化)
if has('syntax')
  syntax enable
endif

" ターミナル色数に応じたハイライト調整
set background=dark
if &t_Co >= 256
  " 256色対応なら標準的で見やすいテーマを使用
  try
    colorscheme desert
  catch
    colorscheme default
  endtry
else
  " 色数が少ない環境(8/16色)なら標準に戻す
  colorscheme default
endif

" --- Indent (2 spaces) ---
set expandtab                " Tabをスペースに
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set smartindent

" --- Useful Mappings & Features ---
" バックスペースの挙動を現代的に
set backspace=indent,eol,start

" マウス操作 (機能がある場合のみ)
if has('mouse')
  set mouse=a
endif

" クリップボード (機能がある場合のみ)
if has('clipboard')
  if has('unnamedplus')
    set clipboard^=unnamedplus
  else
    set clipboard^=unnamed
  endif
endif

" ステータスライン (常に表示)
set laststatus=2
" 複雑な式を使わず、軽量で情報量の多いフォーマット
" [ファイルパス][読取専用/変更有][ファイルタイプ][文字コード][改行コード] 右寄せ [行/総行数, 列]
set statusline=%F%m%r%h\ [%Y][%{&fenc!=''?&fenc:&enc}][%{&ff}]\ %=%l/%L,\ %v

" --- Specific Commands ---
" Esc連打で検索ハイライトを消す
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" コピペ時のインデント崩れ防止 (F2でペーストモード切替)
set pastetoggle=<F2>

" 長すぎる行のハイライトを無効化 (パフォーマンス対策)
set synmaxcol=300

" --- Netrw (Standard Filer) ---
" 標準ファイラーを見やすく軽量に
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
