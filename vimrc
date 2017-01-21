" vimrc
" Author: Alex Masterov <alex.masterow@gmail.com>
" Source: https://github.com/AlexMasterov/vimfiles

" Environment
"---------------------------------------------------------------------------
  let $VIMFILES = expand('~/vimfiles')
  let $VIMHOME = expand('~/') . (has('nvim') ? '.nvim' : '.vim')

  let $UNDO  = $VIMHOME . '/undo'
  let $VIEW  = $VIMHOME . '/view'
  let $CACHE = $VIMHOME . '/.cache'
  let $INFO  = $VIMHOME . (has('nvim') ? '/shada' : '/viminfo')

  if has('vim_starting')
    set runtimepath=$VIMFILES,$VIMRUNTIME
  endif

  set noexrc          " avoid reading local (g)vimrc, exrc
  set modelines=0     " prevents security exploits
  set regexpengine=2  " 0=auto 1=old 2=NFA
  set packpath=

  " Initialize autogroup
  augroup MyVimrc | execute 'autocmd!' | augroup END

  " Echo startup time on start
  if has('reltime') && has('vim_starting')
    " Shell: vim --startuptime filename -q; vim filename
    " vim --cmd 'profile start profile.txt' --cmd 'profile file $HOME/.vimrc' +q && vim profile.txt
    let s:startupTime = reltime()
    autocmd MyVimrc VimEnter * let s:startupTime = reltime(s:startupTime) | redraw
                    \| echomsg ' startuptime:'. reltimestr(s:startupTime)
  endif

" Commands
"---------------------------------------------------------------------------
  command! -nargs=* Autocmd   autocmd MyVimrc <args>
  command! -nargs=* AutocmdFT autocmd MyVimrc FileType <args>
  command! -nargs=1 Data
        \ execute 'set ' . (has('nvim') ? 'shada' : 'viminfo') . '='.<q-args>
  command! -nargs=1 Indent
        \ execute 'setlocal tabstop='.<q-args> 'softtabstop='.<q-args> 'shiftwidth='.<q-args>
  " Shows the syntax stack under the cursor
  command! SS echo map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")

" Events
"---------------------------------------------------------------------------
  Autocmd VimEnter * filetype plugin indent on
  " Remove quit command from history
  Autocmd VimEnter * call histdel(':', '^w\?q\%[all]!\?$')
  " Don't auto comment new line made with 'o', 'O', or <CR>
  Autocmd WinEnter * setlocal formatoptions-=ro
  Autocmd WinEnter * checktime
  Autocmd WinLeave * let [&l:number, &l:relativenumber] = &l:number ? [1, 0] : [&l:number, &l:relativenumber]
  Autocmd WinEnter * let [&l:number, &l:relativenumber] = &l:number ? [1, 1] : [&l:number, &l:relativenumber]
  Autocmd InsertEnter * setlocal list
  Autocmd InsertLeave * setlocal nolist
  Autocmd Syntax * if 5000 < line('$') | syntax sync minlines=200 | endif
  if exists('$MYVIMRC')
    Autocmd BufWritePost $MYVIMRC | source $MYVIMRC | redraw
  endif

" Functions
"---------------------------------------------------------------------------
  let s:isWindows = has('win64') || has('win32') || has('win32unix')
  function! IsWindows() abort
    return s:isWindows
  endfunction

  function! s:trimWhiteSpace() abort
    if &binary | return | endif
    let [winView, register] = [winsaveview(), @/]
    silent %s/\s\+$//ge
    call winrestview(winView) | let @/ = register
  endfunction

  nnoremap <silent> ,<Space> :<C-u>TrimWhiteSpace<CR>
  command! -nargs=* -complete=file TrimWhiteSpace f <args> | call s:trimWhiteSpace()
  Autocmd BufWritePre,FileWritePre *? call s:trimWhiteSpace()

  " ---
  function! s:makeDir(name, ...) abort
    let force = a:0 >= 1 && a:1 ==# '!'
    let name = expand(a:name, 1)
    if !isdirectory(name)
      \ && (force || input('^y\%[es]$' =~? printf('"%s" does not exist. Create? [yes/no]', name)))
      silent call mkdir(iconv(name, &encoding, &termencoding), 'p')
    endif
  endfunction

  command! -nargs=1 -bang MakeDir call s:makeDir(<f-args>, "<bang>")
  Autocmd BufWritePre,FileWritePre *? call s:makeDir('<afile>:h', v:cmdbang)

" Encoding
"---------------------------------------------------------------------------
  set encoding=utf-8
  scriptencoding utf-8

  if IsWindows()
    set fileencodings=utf-8,cp1251
    set termencoding=cp850  " cmd.exe uses cp850
  else
    set termencoding=       " same as 'encoding'
  endif

  " Default fileformat
  set fileformat=unix fileformats=unix,dos,mac

  " Open in UTF-8
  command! -nargs=? -bar -bang -complete=file Utf8 edit<bang> ++enc=utf-8 <args>
  " Open in CP1251
  command! -nargs=? -bar -bang -complete=file Cp1251 edit<bang> ++enc=cp1251 <args>

  " Misc
"---------------------------------------------------------------------------
  Data !,'300,<50,s10,h,n$INFO

  " Cache
  MakeDir! $CACHE
  set directory=$VIMFILES/tmp
  set noswapfile

  " Undo
  MakeDir! $UNDO
  set undodir=$UNDO
  set undofile undolevels=500 undoreload=1000

  " View
  set viewdir=$VIEW
  set viewoptions=cursor,slash,unix

  " Russian keyboard
  set keymap=russian-jcukenwin
  set iskeyword=@,48-57,_,192-255
  set iminsert=0 imsearch=0

" Plugins
"---------------------------------------------------------------------------
  " Avoid loading same default plugins
  let g:loaded_csv = 1
  let g:loaded_gzip = 1
  let g:loaded_zipPlugin = 1
  let g:loaded_tarPlugin = 1
  let g:loaded_logiPat = 1
  let g:loaded_rrhelper = 1
  let g:loaded_matchparen = 1
  let g:loaded_parenmatch = 1
  let g:loaded_netrwPlugin = 1
  let g:loaded_2html_plugin = 1
  let g:loaded_vimballPlugin = 1
  let g:loaded_getscriptPlugin = 1
  let g:loaded_spellfile_plugin = 1
  let g:did_install_syntax_menu = 1
  let g:did_install_default_menus = 1

  " Setup Dein plugin manager
  if has('vim_starting')
    let s:deinPath = $VIMHOME . '/dein'
    let s:deinRepo = s:deinPath.'/repos/github.com/Shougo/dein.vim'
    if !isdirectory(s:deinRepo)
      if executable('git')
        let s:deinUri = 'https://github.com/Shougo/dein.vim.git'
        call system(printf('git clone --depth 1 %s %s', s:deinUri, fnameescape(s:deinRepo)))
      else
        echom 'Can`t download Dein: Git not found.'
      endif
    endif
    execute 'set runtimepath^='. fnameescape(s:deinRepo)
  endif

  if dein#load_state(s:deinPath)
    call dein#begin(s:deinPath, [expand('<sfile>')])

    call dein#add('Shougo/dein.vim', {
      \ 'rtp': '',
      \ 'hook_add': join([
      \   'let g:dein#types#git#clone_depth = 1',
      \   'let g:dein#install_max_processes = 20',
      \   'nnoremap <silent> ;u :<C-u>call dein#update()<CR>',
      \   'nnoremap <silent> ;i :<C-u>call dein#install()<CR>',
      \   'nnoremap <silent> ;I :<C-u>call map(dein#check_clean(), "delete(v:val, ''rf'')")<CR>'
      \], "\n")
      \})

    " Load develop version plugins
    call dein#local($VIMFILES.'/dev', {'frozen': 1, 'merged': 0},  ['dotvim'])

    call dein#add('AlexMasterov/mild.vim')
    call dein#add('Shougo/vimproc.vim', {
      \ 'build': IsWindows() ? 'tools\\update-dll-mingw' : 'make',
      \ 'on_source': ['unite.vim', 'vim-quickrun', 'ternjs.vim']
      \})

    call dein#add('kopischke/vim-stay', {'on_path': '.*'})
    call dein#add('mbbill/undotree', {'on_cmd': 'UndotreeToggle'})
    call dein#add('kana/vim-smartchr')

    " Lint
    "-----------------------------------------------------------------------
    call dein#add('w0rp/ale', {
      \ 'on_func': 'ale#',
      \ 'hook_add': join([
      \   'nmap <silent> <Right> <Plug>(ale_next_wrap)',
      \   'nmap <silent> <Left>  <Plug>(ale_previous_wrap)',
      \   'Autocmd BufNewFile,BufEnter,BufWrite,WinEnter,TextChanged,TextChangedI *.{php,js}',
      \     '\ call ale#Queue(200)',
      \   'Autocmd ColorScheme *',
      \     '\  hi ALEErrorSign   guifg=#2B2B2B guibg=#FFC08E gui=bold',
      \     '\| hi ALEWarningSign guifg=#2B2B2B guibg=#F2E8DF gui=bold',
      \], "\n"),
      \ 'hook_source': join([
      \   "let g:ale_echo_cursor = 0",
      \   "let g:ale_lint_on_save = 0",
      \   "let g:ale_lint_on_enter = 0",
      \   "let g:ale_lint_on_text_changed = 0",
      \   "let g:ale_sign_error = '->'",
      \   "let g:ale_sign_warning = '—'",
      \   "let g:ale_echo_msg_error_str = 'E'",
      \   "let g:ale_echo_msg_warning_str = 'W'",
      \   "let g:ale_echo_msg_format = ' %s'",
      \   "let g:ale_sign_column_always = 1",
      \   "let g:ale_linters = {'php': ['php'], 'javascript': ['eslint']}",
      \   "let g:ale_javascript_eslint_use_global = 1",
      \   "let g:ale_javascript_eslint_options = printf('--cache --no-color --config %s/preset/eslint.js', $VIMFILES)"
      \], "\n")
      \})

    " Task Runner
    "-----------------------------------------------------------------------
    call dein#add('thinca/vim-quickrun', {
      \ 'rev': 'v0.7.0',
      \ 'frozen': 1,
      \ 'on_cmd': 'QuickRun',
      \ 'on_map': [['n', '<Plug>(quickrun)']]
      \})
    call dein#add('miyakogi/vim-quickrun-job')

    " Bundles
    call dein#local($VIMFILES.'/dev', {'frozen': 1}, ['quickrun'])

    " Neocomplete
    "-----------------------------------------------------------------------
    call dein#add('Shougo/neocomplete.vim', {
      \ 'depends': 'context_filetype.vim',
      \ 'on_event': 'InsertEnter'
      \})

    " Plugins
    call dein#add('Shougo/context_filetype.vim', {
      \ 'hook_add': 'let g:context_filetype#search_offset = 500'
      \})
    call dein#add('Shougo/echodoc.vim', {
      \ 'on_source': 'neocomplete.vim',
      \ 'hook_source': 'let g:echodoc_enable_at_startup = 1'
      \})

    " Sources
    call dein#add('Shougo/neco-vim', {
      \ 'on_source': 'neocomplete.vim'
      \})
    call dein#add('Shougo/neoinclude.vim', {
      \ 'on_source': 'neocomplete.vim'
      \})
    call dein#add('hrsh7th/vim-neco-calc')
    " call dein#add('racer-rust/vim-racer', {
    "   \ 'if': executable('racer'),
    "   \ 'on_source': 'neocomplete.vim'
    "   \})

    " Snippets
    call dein#add('SirVer/ultisnips', {
      \ 'on_source': 'neocomplete.vim',
      \ 'hook_source': 'Autocmd VimEnter * silent! au! UltiSnipsFileType'
      \})
    call dein#local($VIMFILES.'/dev', {'frozen': 1, 'merged': 0}, ['snippetus'])

    " Unite / Denite
    "-----------------------------------------------------------------------
    call dein#add('Shougo/unite.vim', {'on_cmd': 'Unite'})
    call dein#add('Shougo/denite.nvim', {'on_cmd': 'Denite'})

    " Plugins
    call dein#add('thinca/vim-qfreplace', {'on_source': 'unite.vim'})

    " Sources
    call dein#add('Shougo/neomru.vim', {
      \ 'on_source': ['unite.vim', 'denite.nvim'],
      \ 'on_path': '.*',
      \ 'on_func': 'neomru#_save',
      \ 'hook_add': join([
      \   'nnoremap <silent> ;w :<C-u>Unite neomru/file -toggle -profile-name=neomru/project<CR>',
      \   'nnoremap <silent> ;W :<C-u>Unite neomru/file -toggle<CR>',
      \   'Autocmd VimLeavePre,BufWipeout,BufLeave,WinLeave * call neomru#_save()'
      \], "\n"),
      \ 'hook_source': join([
      \   "let g:neomru#filename_format = ':.'",
      \   "let g:neomru#time_format = '%m.%d %H:%M — '",
      \   "let g:neomru#file_mru_limit = 180",
      \   "let g:neomru#file_mru_path = $CACHE.'/unite/mru_file'",
      \   "let g:neomru#file_mru_ignore_pattern = '\.\%(log\|vimrc\)$'",
      \   "let g:neomru#directory_mru_path = $CACHE.'/unite/mru_directory'",
      \   "call unite#custom#profile('neomru/project', 'matchers', ['matcher_hide_current_file', 'matcher_project_files', 'matcher_fuzzy'])"
      \], "\n")
      \})
    call dein#add('Shougo/neoyank.vim', {
      \ 'on_source': ['unite.vim', 'denite.nvim'],
      \ 'hook_add': 'nnoremap <silent> ;y :<C-u>Denite neoyank -no-statusline -mode=normal<CR>',
      \ 'hook_source': join([
      \   "let g:neoyank#limit = 50",
      \   "let g:neoyank#file = $CACHE.'/unite/yank_file'"
      \], "\n")
      \})
    call dein#add('Shougo/unite-outline', {
      \ 'hook_add': 'nnoremap <silent> ;; :<C-u>Unite outline -silent -no-empty -toggle -winheight=16<CR>'
      \})
    call dein#add('mattn/httpstatus-vim', {
      \ 'hook_add': 'nnoremap <silent> <F12> :<C-u>Unite httpstatus -start-insert<CR>'
      \})
    call dein#add('pasela/unite-webcolorname', {
      \ 'hook_add': 'nnoremap <silent> <F11> :<C-u>Unite webcolorname -buffer-name=colors -start-insert<CR>'
      \})
    call dein#local($VIMFILES.'/dev', {
      \ 'frozen': 1, 'merged': 0,
      \ 'hook_add': 'nnoremap <silent> ;l :<C-u>Unite location_list -no-empty -toggle<CR>',
      \}, ['unite-location'])

    " Text-objects
    "-----------------------------------------------------------------------
    call dein#add('kana/vim-textobj-user')
    call dein#add('machakann/vim-textobj-delimited', {
      \ 'depends': 'vim-textobj-user',
      \ 'on_map': ['vid', 'viD', 'vad', 'vaD']
      \})
    call dein#add('whatyouhide/vim-textobj-xmlattr', {
      \ 'depends': 'vim-textobj-user',
      \ 'on_map': ['vix', 'vax']
      \})

    " Operators
    "-----------------------------------------------------------------------
    call dein#add('kana/vim-operator-user')
    call dein#add('rhysd/vim-operator-surround', {
      \ 'depends': 'vim-operator-user',
      \ 'on_map': [['v', '<Plug>(operator-surround-']],
      \ 'hook_add': join([
      \   'vmap sa <Plug>(operator-surround-append)',
      \   'vmap sd <Plug>(operator-surround-delete)',
      \   'vmap sr <Plug>(operator-surround-replace)'
      \], "\n")
      \})
    call dein#add('tyru/operator-reverse.vim', {
      \ 'depends': 'vim-operator-user',
      \ 'on_map': [['v', '<Plug>(operator-reverse-']],
      \ 'hook_add': join([
      \   'vmap <silent> sw <Plug>(operator-reverse-text)',
      \   'vmap <silent> sl <Plug>(operator-reverse-lines)'
      \], "\n")
      \})
    call dein#add('romgrk/replace.vim', {
      \ 'on_map': [['nx', '<Plug>ReplaceOperator']],
      \ 'hook_add': join([
      \   'nmap <silent> R <Plug>ReplaceOperator',
      \   'xmap <silent> R <Plug>ReplaceOperator'
      \], "\n")
      \})
    call dein#add('haya14busa/vim-operator-flashy', {
      \ 'depends': 'vim-operator-user',
      \ 'on_map': [['n', '<Plug>(operator-flashy)']],
      \ 'hook_add': join([
      \   'nmap y <Plug>(operator-flashy)',
      \   'nmap Y <Plug>(operator-flashy)$'
      \], "\n"),
      \ 'hook_source': join([
      \   'let g:operator#flashy#flash_time = 280',
      \   "let g:operator#flashy#group = 'Visual'"
      \], "\n")
      \})

    call dein#add('tpope/vim-surround', {
      \ 'on_map': [['n', '<Plug>D'], ['n', '<Plug>C'], ['n', '<Plug>Y'], ['x', '<Plug>V']],
      \ 'hook_add': join([
      \   'nmap ,d <Plug>Dsurround',
      \   'nmap ,i <Plug>Csurround',
      \   'nmap ,I <Plug>CSurround',
      \   'nmap ,t <Plug>Yssurround',
      \   'nmap ,T <Plug>YSsurround',
      \   'xmap ,s <Plug>VSurround',
      \   'xmap ,S <Plug>VgSurround',
      \   "for char in split('` '' \" ( ) { } [ ]')",
      \   "  execute printf('nmap ,%s ,Iw%s', char, char)",
      \   "endfor | unlet char"
      \], "\n"),
      \ 'hook_source': 'let g:surround_no_mappings = 1'
      \})

    call dein#add('triglav/vim-visual-increment', {
      \ 'on_map': [['x', '<Plug>Visual']],
      \ 'hook_add': join([
      \   'xmap <C-a> <Plug>VisualIncrement',
      \   'xmap <C-x> <Plug>VisualDecrement'
      \], "\n"),
      \ 'hook_source': 'set nrformats+=alpha'
      \})

    call dein#add('haya14busa/vim-keeppad', {
      \ 'on_cmd': ['KeeppadOn', 'KeeppadOff'],
      \ 'hook_add': 'Autocmd BufReadPre *.{json,css,scss,sss,sugarss},qfreplace* KeeppadOn',
      \ 'hook_source': 'let g:keeppad_autopadding = 0'
      \})

    call dein#add('kana/vim-smartword', {
      \ 'on_map': [['nx', '<Plug>(smartword-']],
      \ 'hook_add': join([
      \   "for char in split('w e b ge')",
      \   "  execute printf('nmap %s <Plug>(smartword-%s)', char, char)",
      \   "  execute printf('vmap %s <Plug>(smartword-%s)', char, char)",
      \   "endfor | unlet char"
      \], "\n")
      \})

    call dein#add('tyru/caw.vim', {
      \ 'on_map': [['nx', '<Plug>(caw:']],
      \ 'hook_add': join([
      \   'nmap  q <Plug>(caw:range:toggle)',
      \   'xmap  q <Plug>(caw:hatpos:toggle)',
      \   'nmap ,f <Plug>(caw:jump:comment-prev)',
      \   'nmap ,F <Plug>(caw:jump:comment-next)',
      \   'nmap ,a <Plug>(caw:dollarpos:toggle)'
      \], "\n"),
      \ 'hook_source': join([
      \   'let g:caw_no_default_keymappings = 1',
      \   'let g:caw_hatpos_skip_blank_line = 1',
      \   'let g:caw_dollarpos_sp_left = repeat("\u0020", 2)'
      \], "\n"),
      \})

    call dein#add('AndrewRadev/splitjoin.vim', {
      \ 'on_cmd': 'SplitjoinSplit',
      \ 'hook_add': 'nmap <silent> S :<C-u>SplitjoinSplit<CR><CR><Esc>'
      \})

    call dein#add('jakobwesthoff/argumentrewrap', {
      \ 'hook_add': 'map <silent> K :<C-u>call argumentrewrap#RewrapArguments()<CR>'
      \})

    call dein#add('junegunn/vim-easy-align', {
      \ 'on_map': [['nx', '<Plug>(EasyAlign)']],
      \ 'hook_add': 'vmap <Enter> <Plug>(EasyAlign)'
      \})

    call dein#add('easymotion/vim-easymotion', {
      \ 'on_func': 'EasyMotion#go',
      \ 'on_map': [['nx', '<Plug>(easymotion-']]
      \})

    call dein#add('AndrewRadev/sideways.vim', {
      \ 'on_cmd': 'Sideways',
      \ 'hook_add': join([
      \   'nnoremap <silent> <C-h> :<C-u>SidewaysLeft<CR>',
      \   'nnoremap <silent> <C-l> :<C-u>SidewaysRight<CR>',
      \   'nnoremap <silent> <S-h> :<C-u>SidewaysJumpLeft<CR>',
      \   'nnoremap <silent> <S-l> :<C-u>SidewaysJumpRight<CR>'
      \], "\n")
      \})

    call dein#add('cohama/lexima.vim', {
      \ 'on_event': 'InsertEnter',
      \ 'hook_add': 'let g:lexima_no_default_rules = 1'
      \})

    call dein#add('AndrewRadev/switch.vim', {
      \ 'on_func': 'switch#',
      \ 'on_cmd': 'Switch',
      \ 'hook_source': "let g:switch_mapping = ''"
      \})

    call dein#add('Shougo/vimfiler.vim', {
      \ 'on_if': "isdirectory(bufname('%'))",
      \ 'on_cmd': ['VimFiler', 'VimFilerCurrentDir'],
      \ 'on_map': [['n', '<Plug>']]
      \})

    call dein#add('t9md/vim-choosewin', {
      \ 'on_map': [['n', '<Plug>(choosewin)']],
      \ 'hook_add': join([
      \   'nmap - <Plug>(choosewin)',
      \   'AutocmdFT vimfiler nmap <buffer> - <Plug>(choosewin)'
      \], "\n"),
      \ 'hook_source': join([
      \   "let g:choosewin_label = 'WERABC'",
      \   "let g:choosewin_label_align = 'left'",
      \   'let g:choosewin_blink_on_land = 0',
      \   'let g:choosewin_overlay_enable = 2',
      \   "let g:choosewin_color_land = {'gui': ['#0000FF', '#F6F7F7', 'NONE']}",
      \   "let g:choosewin_color_label = {'gui': ['#FFE1CC', '#2B2B2B', 'bold']}",
      \   "let g:choosewin_color_label_current = {'gui': ['#CCE5FF', '#2B2B2B', 'bold']}",
      \   "let g:choosewin_color_other = {'gui': ['#F6F7F7', '#EEEEEE', 'NONE']}",
      \   "let g:choosewin_color_shade = {'gui': ['#F6F7F7', '#EEEEEE', 'NONE']}",
      \   "let g:choosewin_color_overlay = {'gui': ['#2B2B2B', '#2B2B2B', 'bold']}",
      \   "let g:choosewin_color_overlay_current = {'gui': ['#CCE5FF', '#CCE5FF', 'bold']}"
      \], "\n")
      \})

    call dein#add('whatyouhide/vim-lengthmatters', {
      \ 'on_cmd': 'Lengthmatters',
      \ 'hook_add': 'AutocmdFT php,javascript,haskell,rust LengthmattersEnable',
      \ 'hook_source': join([
      \   'let g:lengthmatters_on_by_default = 0',
      \   "let g:lengthmatters_excluded = split('vim help markdown unite vimfiler undotree qfreplace')",
      \   "call lengthmatters#highlight_link_to('ColorColumn')"
      \], "\n")
      \})

    call dein#add('itchyny/vim-parenmatch', {
      \ 'hook_add': join([
      \   'let g:parenmatch = 0',
      \   'Autocmd ColorScheme,Syntax * hi ParenMatch guifg=#2B2B2B guibg=#EEEEEE gui=NONE',
      \   'AutocmdFT php,javascript,json,css'
      \   . ' Autocmd BufRead,BufEnter <buffer> let b:parenmatch = 1'
      \], "\n")
      \})

    call dein#add('lilydjwg/colorizer', {
      \ 'on_cmd': ['ColorToggle', 'ColorHighlight', 'ColorClear'],
      \ 'hook_source': 'let g:colorizer_nomap = 1'
      \})

    " File-types
    "-----------------------------------------------------------------------
    " PHP
    call dein#add('2072/PHP-Indenting-for-VIm')
    call dein#add('tobyS/vmustache')
    call dein#add('shawncplus/phpcomplete.vim')
    call dein#add('tobyS/pdv', {
      \ 'depends': 'vmustache',
      \ 'on_func': 'pdv#',
      \ 'hook_add': 'AutocmdFT php nnoremap <silent> <buffer> ,c :<C-u>silent! call pdv#DocumentWithSnip()<CR>',
      \ 'hook_source': "let g:pdv_template_dir = $VIMFILES.'/dev/dotvim/templates'"
      \})
    call dein#add('arnaud-lb/vim-php-namespace', {
      \ 'on_func': 'PhpSortUse',
      \ 'hook_add': 'AutocmdFT php nnoremap <silent> <buffer> ;x :<C-u>silent! call PhpSortUse()<CR>'
      \})

    " Twig
    call dein#add('tokutake/twig-indent')
    call dein#local($VIMFILES.'/dev', {
      \ 'frozen': 1, 'merged': 0,
      \}, ['twig.vim'])

    " Blade
    call dein#add('jwalton512/vim-blade')

    " JavaScript
    call dein#add('othree/jspc.vim')
    call dein#add('heavenshell/vim-jsdoc')
    call dein#add('chemzqm/vim-jsx-improve', {
      \ 'hook_add': join([
      \   'let g:javascript_plugin_jsdoc = 1',
      \   'Autocmd Syntax javascript',
      \     '\  hi jsBraces              guifg=#999999 gui=NONE',
      \     '\| hi jsFuncBraces          guifg=#999999 gui=NONE',
      \     '\| hi jsBrackets            guifg=#999999 gui=NONE',
      \     '\| hi jsParens              guifg=#999999 gui=NONE',
      \     '\| hi jsDestructuringBraces guifg=#999999 gui=NONE',
      \     '\| hi jsParensIfElse        guifg=#999999 gui=NONE',
      \     '\| hi jsGlobalNodeObjects   guifg=#4091bf gui=NONE',
      \     '\| hi jsImport              guifg=#1E347B gui=NONE',
      \     '\| hi jsFrom                guifg=#1E347B gui=NONE',
      \], "\n")
      \})

    call dein#local($VIMFILES.'/dev', {
      \ 'frozen': 1, 'merged': 0,
      \ 'on_cmd': ['TernjsRun', 'TernjsStop'],
      \ 'hook_add': 'AutocmdFT javascript TernjsRun'
      \}, ['ternjs.vim'])

    " HTML
    call dein#add('othree/html5.vim', {
      \ 'hook_add': 'Autocmd Syntax html hi! link htmlError htmlTag | hi! link htmlTagError htmlTag'
      \})
    call dein#add('gregsexton/MatchTag', {
      \ 'hook_add': join([
      \   'Autocmd Syntax xml runtime ftplugin/xml.vim',
      \   'Autocmd Syntax twig,blade runtime ftplugin/html.vim'
      \], "\n")
      \})
    call dein#add('mattn/emmet-vim', {
      \ 'on_map': [['i', '<Plug>(emmet-']],
      \ 'hook_source': join([
      \   "let g:user_emmet_mode = 'i'",
      \   'let g:user_emmet_complete_tag = 0',
      \   'let g:user_emmet_install_global = 0'
      \], "\n")
      \})

    " CSS
    " call dein#add('hail2u/vim-css3-syntax')
    call dein#add('JulesWang/css.vim')
    call dein#add('othree/csscomplete.vim')
    call dein#add('rstacruz/vim-hyperstyle', {
      \ 'build': 'rm -f ' . dein#util#_get_base_path() . '/repos/github.com/rstacruz/vim-hyperstyle/doc/hyperstyle.txt',
      \ 'on_map': [['i', '<Plug>(hyperstyle']],
      \ 'hook_post_source': 'augroup hyperstyle | autocmd! | augroup END'
      \})

    " PostCSS (Sugar)
    call dein#local($VIMFILES.'/dev', {'frozen': 1, 'merged': 0},  ['sugarss.vim'])
    call dein#add('hhsnopek/vim-sugarss', {
      \ 'hook_add': join([
      \   'Autocmd BufNewFile,BufRead *.sss setlocal filetype=sugarss syntax=sss commentstring=//%s',
      \   'AutocmdFT sugarss setlocal nonumber norelativenumber nowrap | Indent 2',
      \   'Autocmd Syntax sugarss',
      \     '\  hi sssClass            guifg=#2B2B2B guibg=#F6F7F7 gui=bold',
      \     '\| hi sssElement          guifg=#2B2B2B guibg=#F6F7F7 gui=NONE',
      \     '\| hi sssProperty         guifg=#0050B0 guibg=#F6F7F7 gui=NONE',
      \     '\| hi sssPropertyOverride guifg=#999999 guibg=#F6F7F7 gui=NONE',
      \     '\| hi sssAbsoluteUnit     guifg=#A67F59 guibg=#F6F7F7 gui=NONE'
      \], "\n")
      \})

    " JSON
    call dein#add('elzr/vim-json', {
      \ 'hook_source': join([
      \   'let g:vim_json_warnings = 0',
      \   "let g:vim_json_syntax_concealcursor = 'n'"
      \], "\n")
      \})

    " CSV
    call dein#add('chrisbra/csv.vim')

    " SVG
    call dein#add('aur-archive/vim-svg')
    call dein#add('jasonshell/vim-svg-indent')

    " Nginx
    call dein#add('yaroot/vim-nginx', {
      \ 'hook_add': 'Autocmd BufNewFile,BufRead */nginx/** setlocal filetype=nginx commentstring=#%s'
      \})

    call dein#end()
    call dein#save_state()
  endif

  if !has('vim_starting') && dein#check_install()
    call dein#install()
  endif

" Plugin settings
"---------------------------------------------------------------------------
  if dein#tap('caw.vim')
    nnoremap <silent> <Plug>(caw:range:toggle) :<C-u>call <SID>cawRangeToggle()<CR>
    function! s:cawRangeToggle() abort
      if v:count > 1
        let winView = winsaveview()
        execute "normal V". (v:count - 1) ."j\<Plug>(caw:hatpos:toggle)"
        call winrestview(winView)
      else
        execute "normal \<Plug>(caw:hatpos:toggle)"
      endif
    endfunction
  endif

  if dein#tap('vim-easy-align')
    function! s:vimEasyAlignOnSource() abort
      let g:easy_align_ignore_groups = ['Comment', 'String']
      let g:easy_align_delimiters = {
        \ '>': {
        \   'pattern': '>>\|=>\|>'
        \ },
        \ ']': {
        \   'pattern': '[[\]]',
        \   'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0
        \ },
        \ ')': {
        \   'pattern': '[()]',
        \   'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0
        \ },
        \ 'f': {
        \   'pattern': ' \(\S\+(\)\@=',
        \   'left_margin': 0, 'right_margin': 0
        \ },
        \ 'd': {
        \   'pattern': ' \(\S\+\s*[;=]\)\@=',
        \   'left_margin': 0, 'right_margin': 0
        \ },
        \ ';': {
        \   'pattern': ':',
        \   'left_margin': 0, 'right_margin': 1, 'stick_to_left': 1
        \ },
        \ '/': {
        \   'pattern': '//\+\|/\*\|\*/',
        \   'ignore_groups': ['^\(.\(Comment\)\@!\)*$'],
        \   'delimiter_align': 'l'
        \ },
        \ '=': {
        \   'pattern': '===\|<=>\|=\~[#?]\?\|=>\|[:+/*!%^=><&|.-?]*=[#?]\?\|[-=]>\|<[-=]',
        \   'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0
        \ }
        \}
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:vimEasyAlignOnSource'))
  endif

  if dein#tap('lexima.vim')
    function! s:leximaOnSource() abort
      silent! call remove(g:lexima#default_rules, 11, -1) " prev 30
      for rule in g:lexima#default_rules + g:lexima#newline_rules
        call lexima#add_rule(rule)
      endfor | unlet rule

      function! s:disableLeximaInsideRegexp(char) abort
        call lexima#add_rule({'at': '\(...........\)\?/\S.*\%#.*\S/', 'char': a:char, 'input': a:char})
      endfunction

      " Quotes
      for quote in split('" ''')
        call lexima#add_rule({'at': '\(.......\)\?'. quote .'\%#', 'char': quote, 'input': quote})
        call lexima#add_rule({'at': '\(...........\)\?\%#'. quote, 'char': quote, 'input': '<Right>'})
        call lexima#add_rule({'at': '\(.......\)\?'. quote .'\%#'. quote, 'char': '<BS>', 'delete': 1})
        call s:disableLeximaInsideRegexp(quote)
      endfor | unlet quote

      " Fix pair completion
      for pair in split('() []')
        call lexima#add_rule({
        \ 'at': '\(........\)\?\%#[^\s'.escape(pair[1], ']') .']', 'char': pair[0], 'input': pair[0]
        \})
      endfor | unlet pair

      " { <Space> }
      call lexima#add_rule({
        \ 'filetype': ['javascript', 'yaml'],
        \ 'at': '\(.......\)\?{\%#}', 'char': '<Space>', 'input_after': '<Space>'
        \})

      " {{ <Space> }}
      call lexima#add_rule({
        \ 'filetype': ['twig', 'blade'],
        \ 'at': '\(........\)\?{\%#}', 'char': '{', 'input': '{<Space>', 'input_after': '<Space>}'
        \})
      call lexima#add_rule({
        \ 'filetype': ['twig', 'blade'],
        \ 'at': '\(........\)\?{{ \%# }}', 'char': '<BS>', 'input': '<BS><BS>', 'delete': 2
        \})
      " {# <Space> #}
      call lexima#add_rule({
        \ 'filetype': 'twig',
        \ 'at': '\(........\)\?{\%#}', 'char': '#', 'input': '#<Space><Space>#<Left><Left>'
        \})
      call lexima#add_rule({
        \ 'filetype': 'twig',
        \ 'at': '\(........\)\?{# \%# #}', 'char': '<BS>', 'input': '<Right><Right><BS><BS><BS>', 'delete': 2
        \})
      " {# <Space> #}
      call lexima#add_rule({
        \ 'filetype': 'twig',
        \ 'at': '{\%#}', 'char': '%', 'input': '%<Space><Space>%<Left><Left>'
        \})
      call lexima#add_rule({
        \ 'filetype': 'twig',
        \ 'at': '{% \%# %}', 'char': '<BS>', 'input': '<Right><Right><BS><BS><BS>', 'delete': 2
        \})
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:leximaOnSource'))
  endif

  if dein#tap('switch.vim')
    nnoremap <silent> <S-Tab> :<C-u>silent! Switch<CR>
    xnoremap <silent> <S-Tab> :silent! Switch<CR>
    nnoremap <silent> ! :<C-u>silent! call switch#Switch(g:switchQuotes, {'reverse': 1})<CR>
    nnoremap <silent> @ :<C-u>silent! call switch#Switch(g:switchCamelCase, {'reverse': 1})<CR>

    let g:switchQuotes = [
      \ {
      \  '''\(.\{-}\)''': '"\1"',
      \  '"\(.\{-}\)"':   '''\1''',
      \  '`\(.\{-}\)`':   '''\1'''
      \ }
      \]
    let g:switchCamelCase = [
      \ {
      \  '\<\(\l\)\(\l\+\(\u\l\+\)\+\)\>': '\=toupper(submatch(1)) . submatch(2)',
      \  '\<\(\u\l\+\)\(\u\l\+\)\+\>':     "\\=tolower(substitute(submatch(0), '\\(\\l\\)\\(\\u\\)', '\\1_\\2', 'g'))",
      \  '\<\(\l\+\)\(_\l\+\)\+\>':        '\U\0',
      \  '\<\(\u\+\)\(_\u\+\)\+\>':        "\\=tolower(substitute(submatch(0), '_', '-', 'g'))",
      \  '\<\(\l\+\)\(-\l\+\)\+\>':        "\\=substitute(submatch(0), '-\\(\\l\\)', '\\u\\1', 'g')"
      \ }
      \]

    AutocmdFT php
      \ let b:switch_custom_definitions = [
      \  ['prod', 'dev', 'test'],
      \  ['&&', '||'],
      \  ['and', 'or'],
      \  ['public', 'protected', 'private'],
      \  ['extends', 'implements'],
      \  ['string ', 'int ', 'array '],
      \  ['use', 'namespace'],
      \  ['var_dump', 'print_r'],
      \  ['include', 'require'],
      \  ['include_once', 'require_once'],
      \  ['$_GET', '$_POST', '$_REQUEST'],
      \  ['__DIR__', '__FILE__'],
      \  {
      \    '\([^=]\)===\([^=]\)': '\1==\2',
      \    '\([^=]\)==\([^=]\)': '\1===\2'
      \  },
      \  {
      \    '\[[''"]\(\k\+\)[''"]\]': '->\1',
      \    '\->\(\k\+\)': '[''\1'']'
      \  },
      \  {
      \    '\array(\(.\{-}\))': '[\1]',
      \    '\[\(.\{-}\)]': '\array(\1)'
      \  },
      \  {
      \    '^class\s\(\k\+\)': 'final class \1',
      \    '^final class\s\(\k\+\)': 'abstract class \1',
      \    '^abstract class\s\(\k\+\)': 'trait \1',
      \    '^trait\s\(\k\+\)': 'class \1'
      \  }
      \]

    AutocmdFT javascript
      \ let b:switch_custom_definitions = [
      \  ['get', 'set'],
      \  ['var', 'const', 'let'],
      \  ['<', '>'], ['==', '!=', '==='],
      \  ['left', 'right'], ['top', 'bottom'],
      \  ['getElementById', 'getElementByClassName'],
      \  {
      \    '\function\s*(\(.\{-}\))': '(\1) =>'
      \  }
      \]

    AutocmdFT html,twig,blade
      \ let b:switch_custom_definitions = [
      \  ['h1', 'h2', 'h3'],
      \  ['png', 'jpg', 'gif'],
      \  ['id=', 'class=', 'style='],
      \  {
      \    '<div\(.\{-}\)>\(.\{-}\)</div>': '<span\1>\2</span>',
      \    '<span\(.\{-}\)>\(.\{-}\)</span>': '<div\1>\2</div>'
      \  },
      \  {
      \    '<ol\(.\{-}\)>\(.\{-}\)</ol>': '<ul\1>\2</ul>',
      \    '<ul\(.\{-}\)>\(.\{-}\)</ul>': '<ol\1>\2</ol>'
      \  }
      \]

    AutocmdFT css
      \ let b:switch_custom_definitions = [
      \  ['border-top', 'border-bottom'],
      \  ['border-left', 'border-right'],
      \  ['border-left-width', 'border-right-width'],
      \  ['border-top-width', 'border-bottom-width'],
      \  ['border-left-style', 'border-right-style'],
      \  ['border-top-style', 'border-bottom-style'],
      \  ['margin-left', 'margin-right'],
      \  ['margin-top', 'margin-bottom'],
      \  ['padding-left', 'padding-right'],
      \  ['padding-top', 'padding-bottom'],
      \  ['margin', 'padding'],
      \  ['height', 'width'],
      \  ['min-width', 'max-width'],
      \  ['min-height', 'max-height'],
      \  ['transition', 'animation'],
      \  ['absolute', 'relative', 'fixed'],
      \  ['inline', 'inline-block', 'block', 'flex'],
      \  ['overflow', 'overflow-x', 'overflow-y'],
      \  ['before', 'after'],
      \  ['none', 'block'],
      \  ['left', 'right'],
      \  ['top', 'bottom'],
      \  ['em', 'px', '%'],
      \  ['bold', 'normal'],
      \  ['hover', 'active']
      \]
  endif

  if dein#tap('vim-smartchr')
    AutocmdFT haskell
      \  inoremap <buffer> <expr> \ smartchr#loop('\ ', '\\')
      \| inoremap <buffer> <expr> - smartchr#loop('-', ' -> ', ' <- ')

    AutocmdFT php
      \  inoremap <buffer> <expr> $ smartchr#loop('$', '$this->', '$$')
      \| inoremap <buffer> <expr> > smartchr#loop('>', '=>', '>>')

    AutocmdFT javascript
      \  inoremap <buffer> <expr> $ smartchr#loop('$', 'this.', '$$')
      \| inoremap <buffer> <expr> - smartchr#loop('-', '--', '_')

    AutocmdFT yaml
      \  inoremap <buffer> <expr> > smartchr#loop('>', '%>')
      \| inoremap <buffer> <expr> < smartchr#loop('<', '<%', '<%=')
  endif

  if dein#tap('colorizer')
    let s:color_codes_ft = split('css html twig sugarss')

    Autocmd BufNewFile,BufRead,BufEnter,WinEnter,BufWinEnter *
      \ execute index(s:color_codes_ft, &filetype) ==# -1
        \ ? 'call s:removeColorizerEvent()'
        \ : 'ColorHighlight'

    function! s:removeColorizerEvent() abort
      if !exists('#Colorizer') | return | endif
      augroup Colorizer
        autocmd!
      augroup END
    endfunction
  endif

  if dein#tap('undotree')
    nnoremap <silent> ,u :<C-u>call <SID>undotreeMyToggle()<CR>

    AutocmdFT undotree,diff setlocal nonu nornu colorcolumn=

    function! s:undotreeMyToggle() abort
      if &l:filetype != 'php'
        let s:undotreeLastFiletype = &l:filetype
        AutocmdFT diff Autocmd BufEnter,WinEnter <buffer>
          \ let &l:syntax = s:undotreeLastFiletype
      endif
      UndotreeToggle
    endfunction

    function! s:undotreeOnSource() abort
      function! g:Undotree_CustomMap() abort
        nmap <buffer> o <Enter>
        nmap <buffer> u <Plug>UndotreeUndo
        nmap <buffer> r <Plug>UndotreeRedo
        nmap <buffer> h <Plug>UndotreeGoNextState
        nmap <buffer> l <Plug>UndotreeGoPreviousState
        nmap <buffer> d <Plug>UndotreeDiffToggle
        nmap <buffer> t <Plug>UndotreeTimestampToggle
        nmap <buffer> C <Plug>UndotreeClearHistory
      endfunction

      let g:undotree_WindowLayout = 4
      let g:undotree_SplitWidth = 36
      let g:undotree_SetFocusWhenToggle = 1

      AutocmdFT diff Autocmd BufEnter,WinEnter <buffer>
        \  nnoremap <silent> <buffer> q :<C-u>UndotreeHide<CR>
        \| nnoremap <silent> <buffer> ` :<C-u>UndotreeHide<CR>
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:undotreeOnSource'))
  endif

  if dein#tap('vimfiler.vim')
    " ;d: open vimfiler explrer
    nnoremap <silent> ;d :<C-u>call <SID>createVimFiler()<CR>
    " Tab: jump to vimfiler window
    nnoremap <silent> <Tab> :<C-u>call <SID>jumpToVimfiler()<CR>

    function! s:createVimFiler() abort
      for winnr in filter(range(1, winnr('$')), "getwinvar(v:val, '&filetype') ==# 'vimfiler'")
        if !empty(winnr)
          execute winnr . 'wincmd w' | return
        endif
      endfor
      VimFiler -split -invisible -create -no-quit
    endfunction

    function! s:jumpToVimfiler() abort
      if getwinvar(winnr(), '&filetype') ==# 'vimfiler'
        wincmd p
      else
        for winnr in filter(range(1, winnr('$')), "getwinvar(v:val, '&filetype') ==# 'vimfiler'")
          execute winnr . 'wincmd w'
        endfor
      endif
    endfunction

    " Vimfiler tuning
    AutocmdFT vimfiler let &l:statusline = ' '
    Autocmd BufEnter,WinEnter vimfiler* nested
      \  let &l:statusline = ' '
      \| setlocal nonu nornu nolist cursorline colorcolumn=
      \| Autocmd BufLeave,WinLeave <buffer> setlocal nocursorline

    AutocmdFT vimfiler call s:vimfilerMappings()
    function! s:vimfilerMappings() abort
      silent! nunmap <buffer> <Space>
      silent! nunmap <buffer> <Tab>

      " Normal mode
      nmap <buffer> <C-j> 4j
      nmap <buffer> <C-k> 4k
      nmap <buffer> <C-c> <Esc>
      nmap <buffer> f <Plug>(vimfiler_grep)
      nmap <buffer> H <Plug>(vimfiler_cursor_top)
      nmap <buffer> R <Plug>(vimfiler_redraw_screen)
      nmap <buffer> l <Plug>(vimfiler_expand_tree)
      nmap <buffer> L <Plug>(vimfiler_cd_file)
      nmap <buffer> J <Plug>(vimfiler_switch_to_root_directory)
      nmap <buffer> K <Plug>(vimfiler_switch_to_project_directory)
      nmap <buffer> H <Plug>(vimfiler_switch_to_parent_directory)
      nmap <buffer> o <Plug>(vimfiler_expand_or_edit)
      nmap <buffer> O <Plug>(vimfiler_open_file_in_another_vimfiler)
      nmap <buffer> w <Plug>(vimfiler_expand_tree_recursive)
      nmap <buffer> W <Plug>(vimfiler_toggle_visible_ignore_files)
      nmap <buffer> e <Plug>(vimfiler_toggle_mark_current_line)
      nmap <buffer> E <Plug>(vimfiler_toggle_mark_current_line_up)
      nmap <buffer> <expr> q winnr('$') ==# 1 ? "\<Plug>(vimfiler_hide)" : "\<Plug>(vimfiler_switch_to_other_window)"
      nmap <buffer> <expr> <Enter> vimfiler#smart_cursor_map("\<Plug>(vimfiler_expand_tree)", "\<Plug>(vimfiler_edit_file)")
      nmap <buffer> <nowait> <expr> t vimfiler#do_action('tabopen')
      nmap <buffer> <nowait> <expr> s vimfiler#do_switch_action('split')
      nmap <buffer> <nowait> <expr> S vimfiler#do_switch_action('vsplit')
      nmap <buffer> <nowait> <expr> v vimfiler#do_switch_action('vsplit')
      nmap <buffer> <nowait> n <Plug>(vimfiler_new_file)
      nmap <buffer> <nowait> N <Plug>(vimfiler_make_directory)
      nmap <buffer> <nowait> d <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_delete_file)y
      nmap <buffer> <nowait> D <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_force_delete_file)
      nmap <buffer> <nowait> c <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_copy_file)
      nmap <buffer> <nowait> m <Plug>(vimfiler_mark_current_line)<Plug>(vimfiler_move_file)y
    endfunction

    function! s:vimfilerOnSource() abort
      let g:vimfiler_data_directory = $CACHE.'/vimfiler'
      let g:unite_kind_file_use_trashbox = IsWindows()

      let g:vimfiler_ignore_pattern =
        \ '^\%(\..*\|^.\|.git\|.hg\|bin\|var\|etc\|build\|dist\|vendor\|node_modules\|gulpfile.js\|package.json\)$'

      " Icons
      let g:vimfiler_file_icon = ' '
      let g:vimfiler_tree_leaf_icon = ''
      let g:vimfiler_tree_opened_icon = '▾'
      let g:vimfiler_tree_closed_icon = '▸'
      let g:vimfiler_marked_file_icon = '+'

      " Default profile
      let s:vimfiler_default = {
        \ 'safe': 0,
        \ 'parent': 0,
        \ 'explorer': 1,
        \ 'winwidth': 26,
        \ 'winminwidth': 18
        \}
      call vimfiler#custom#profile('default', 'context', s:vimfiler_default)
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:vimfilerOnSource'))
  endif

  if dein#tap('vim-quickrun')
    nnoremap <expr> <silent> ;Q quickrun#is_running() ? quickrun#sweep_sessions() : "\<C-c>"

    " Runners
    AutocmdFT php
      \ nnoremap <silent> <buffer> ,t :<C-u>call <SID>quickrunType('phpunit')<CR>
    AutocmdFT javascript
      \  nnoremap <silent> <buffer> ,t :<C-u>call <SID>quickrunType('jest')<CR>
      \| nnoremap <silent> <buffer> ,T :<C-u>call <SID>quickrunType('nodejs')<CR>

    " Formatters
    AutocmdFT php,javascript,json,xml,html,twig,css,sugarss
      \ nnoremap <silent> <buffer> ,w :<C-u>call <SID>quickrunType('formatter')<CR>

    Autocmd BufEnter,WinEnter runner:*
      \ let &l:statusline = ' ' | setlocal nonu nornu nolist colorcolumn=

    function! s:quickrunType(type) abort
      let g:quickrun_config = get(g:, 'quickrun_config', {})
      let g:quickrun_config[&filetype] = {'type': printf('%s/%s', &filetype, a:type)}
      call quickrun#run(printf('-%s', a:type))
    endfunction

    function! s:quickrunOnSource() abort
      let g:quickrun_config = get(g:, 'quickrun_config', {})
      let g:quickrun_config._ = {'runner': 'job', 'runner/job/updatetime': 10}

      " PHP
      let g:quickrun_config['php/formatter'] = {
        \ 'command': 'php-cs-fixer', 'exec': '%c %a %s', 'outputter': 'reopen',
        \ 'args': printf('fix -q --config=%s/preset/.php_cs', $VIMFILES)
        \}
      let g:quickrun_config['php/phpunit'] = {
        \ 'command': 'phpunit', 'exec': '%c %a %s', 'outputter': 'phpunit',
        \ 'args': '-c phpunit.xml --tap --stop-on-failure'
        \}

      " JavaScript
      let g:quickrun_config['javascript/nodejs'] = {
        \ 'command': 'node', 'exec': '%c %a %s', 'outputter': 'buffer',
        \ 'outputter/buffer/name': 'runner:nodejs',
        \ 'outputter/buffer/filetype': 'json',
        \ 'outputter/buffer/running_mark': '...'
        \}
      let g:quickrun_config['javascript/formatter'] = {
        \ 'command': 'eslint', 'exec': '%c %a %s', 'outputter': 'reopen',
        \ 'args': printf('--config %s/preset/eslint-fix.js --no-color --fix', $VIMFILES)
        \}
      let g:quickrun_config['javascript/jest'] = {
        \ 'command': 'jest', 'exec': '%c %a', 'outputter': 'jest',
        \ 'args': printf('--config %s/preset/jest.json', $VIMFILES)
        \}

      " CSS
      let g:quickrun_config['css/formatter'] = {
        \ 'command': 'postcss', 'exec': '%c %a %s', 'outputter': 'rebuffer',
        \ 'args': printf('--use postcss-sorting --config %s/preset/postcss_sort.js', $VIMFILES)
        \}
      " let g:quickrun_config['css/formatter'] = {
      "   \ 'command': 'postcss', 'exec': '%c %a %s', 'outputter': 'rebuffer',
      "   \ 'args': printf('--config %s/preset/stylelint.js --no-color', $VIMFILES)
      "   \}
      let g:quickrun_config['sugarss/formatter'] = g:quickrun_config['css/formatter']

      " HTML
      let g:quickrun_config['html/formatter'] = {
        \ 'command': 'html-beautify', 'exec': '%c -f %s %a', 'outputter': 'rebuffer',
        \ 'args': printf('--config %s/preset/beautify.json -q -o', $VIMFILES)
        \}
      " Twig
      let g:quickrun_config['twig/formatter'] = g:quickrun_config['html/formatter']

      " XML
      let g:quickrun_config['xml/formatter'] = {
        \ 'command': 'tidy', 'exec': '%c %a %s', 'outputter': 'rebuffer',
        \ 'args': printf('-config %s/preset/tidy_xml.config', $VIMFILES),
        \}

      " Lua
      let g:quickrun_config['lua/lint'] = {
        \ 'command': IsWindows() ? 'luac53' : 'luac',
        \ 'exec': '%c %a %s', 'args': '-p',
        \ 'outputter': 'luac',
        \ 'errorformat': '%*\f: %#%f:%l: %m'
        \}

      " JSON
      let g:quickrun_config['json/formatter'] = {
        \ 'command': 'js-beautify', 'exec': '%c %s %a', 'outputter': 'rebuffer',
        \ 'args': printf('--config %s/preset/beautify.json -q -f', $VIMFILES)
        \}
      " let g:quickrun_config['json/lint'] = {
      "   \ 'runner': 'vimproc', 'runner/vimproc/updatetime': 120,
      "   \ 'command': 'jsonlint', 'exec': '%c %s %a', 'outputter': 'unite',
      "   \ 'args': '--compact -q',
      "   \ 'errorformat': '%ELine %l:%c, %Z\\s%#Reason: %m, %C%.%#, %f: line %l\, col %c\, %m, %-G%.%#'
      "   \}
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:quickrunOnSource'))
  endif

  if dein#tap('context_filetype.vim')
    function! s:addContext(filetype, context) abort
      let filetype = get(context_filetype#default_filetypes(), a:filetype, [])
      let g:context_filetype#filetypes[a:filetype] = add(filetype, a:context)
    endfunction

    function! s:contextFiletypeOnSource() abort
      let css = {
        \ 'filetype': 'css',
        \ 'start': '<style\%( [^>]*\)\?>', 'end': '</style>'
        \}
      let javascript = {
        \ 'filetype': 'javascript',
        \ 'start': '<script\%( [^>]*\)\?>', 'end': '</script>'
        \}

      for filetype in split('html twig blade')
        call s:addContext(filetype, css)
        call s:addContext(filetype, javascript)
      endfor | unlet filetype
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:contextFiletypeOnSource'))
  endif

  if dein#tap('neocomplete.vim')
    imap <Tab> <Plug>(neocomplete)
    imap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<Plug>(neocomplete)"
    imap <expr> <C-j>   pumvisible() ? "\<C-n>" : "\<C-g>u<C-u>"
    imap <expr> <C-k>   pumvisible() ? "\<C-p>" : col('.') ==# col('$') ? "\<C-k>" : "\<C-o>D"
    " Make <BS> delete letter instead of clearing completion
    inoremap <BS> <BS>

    inoremap <silent> <Plug>(neocomplete) <C-r>=<SID>neoComplete("\<Tab>")<CR>
    function! s:neoComplete(key) abort
      if pumvisible()
        return "\<C-n>"
      endif
      let [curPos, lineLength] = [getcurpos()[4], col('$')]
      let isText = curPos <= lineLength
      let isStartLine = curPos <= 1
      let isBackspace = getline('.')[curPos-2] =~ '\s'
      if isText && !isStartLine && !isBackspace
        return neocomplete#helper#get_force_omni_complete_pos(neocomplete#get_cur_text(1)) >= 0
          \ ? "\<C-x>\<C-o>\<C-r>=neocomplete#mappings#popup_post()\<CR>"
          \ : "\<C-x>\<C-o>"
      endif
      return a:key
    endfunction

    function! s:neocompleteOnSource() abort
      let g:neocomplete#enable_at_startup = 1
      let g:neocomplete#enable_smart_case = 0
      let g:neocomplete#enable_camel_case = 1
      let g:neocomplete#enable_auto_delimiter = 1
      let g:neocomplete#min_keyword_length = 2
      let g:neocomplete#auto_completion_start_length = 2
      let g:neocomplete#manual_completion_start_length = 2

      let g:neocomplete#data_directory = $CACHE.'/neocomplete'
      let g:neocomplete#lock_buffer_name_pattern = '\.log\|.*;tail\|.*quickrun.*'
      let g:neocomplete#sources#buffer#disabled_pattern = g:neocomplete#lock_buffer_name_pattern

      " Custom settings
      call neocomplete#custom#source('tag', 'rank', 60)
      call neocomplete#custom#source('omni', 'rank', 60)
      call neocomplete#custom#source('ultisnips', 'rank', 80)
      call neocomplete#custom#source('ultisnips', 'min_pattern_length', 1)
      call neocomplete#custom#source('_', 'converters', [
        \ 'converter_add_paren',
        \ 'converter_remove_overlap',
        \ 'converter_delimiter',
        \ 'converter_abbr'
        \])

      " Sources
      let g:neocomplete#sources = {
        \ '_':          ['buffer', 'file/include'],
        \ 'vim':        ['vim',  'file/include', 'ultisnips', 'calc'],
        \ 'lua':        ['omni', 'file/include', 'ultisnips', 'calc'],
        \ 'rust':       ['omni', 'file/include', 'ultisnips', 'calc'],
        \ 'javascript': ['omni', 'file/include', 'ultisnips', 'calc'],
        \ 'haskell':    ['omni', 'file/include', 'ultisnips', 'calc'],
        \ 'php':        ['omni', 'file/include', 'ultisnips', 'calc', 'buffer'],
        \ 'html':       ['omni', 'file/include', 'ultisnips'],
        \ 'twig':       ['omni', 'file/include', 'ultisnips'],
        \ 'blade':      ['omni', 'file/include', 'ultisnips'],
        \ 'css':        ['omni', 'file/include', 'ultisnips'],
        \ 'sugarss':    ['omni', 'file/include', 'ultisnips'],
        \ 'xml':        ['omni', 'file/include', 'ultisnips', 'buffer']
        \}

      " Completion patterns
      let g:neocomplete#sources#omni#input_patterns = {
        \ 'haskell':    '\h\w*\|\(import\|from\)\s',
        \ 'lua':        '\w\+[.:]\|require\s*(\?["'']\w*',
        \ 'sql':        '\h\w*\|[^.[:digit:] *\t]\%(\.\)\%(\h\w*\)\?',
        \ 'rust':       '[^.[:digit:] *\t]\%(\.\|\::\)\%(\h\w*\)\?',
        \ 'javascript': '\h\w*\|\h\w*\.\%(\h\w*\)\|[^. \t]\.\%(\h\w*\)',
        \ 'php':        '\h\w*\|[^. \t]->\%(\h\w*\)\?\|\h\w*::\%(\h\w*\)\?'
        \}

      call neocomplete#util#set_default_dictionary('g:neocomplete#sources#omni#input_patterns',
        \ 'html,twig,xml', '<\|\s[[:alnum:]-]*')
      call neocomplete#util#set_default_dictionary('g:neocomplete#sources#omni#input_patterns',
        \ 'css,scss,sass,sss,sugarss', '\w\+\|\w\+[):;]\?\s\+\w*\|[@!]')

      let g:neocomplete#sources#omni#functions = get(g:, 'neocomplete#sources#omni#functions', {})
      let g:neocomplete#sources#dictionary#dictionaries = get(g:, 'neocomplete#sources#dictionary#dictionaries', {})

      " JavaScript
      if dein#tap('ternjs.vim')
        let g:neocomplete#sources#omni#functions.javascript = ['ternjs#Complete']
        " let g:neocomplete#force_omni_input_patterns = get(g:, 'neocomplete#force_omni_input_patterns', {})
        " let g:neocomplete#force_omni_input_patterns.javascript =  g:neocomplete#sources#omni#input_patterns.javascript
      endif
      if dein#tap('jspc.vim')
        let g:neocomplete#sources#omni#functions.javascript = get(g:neocomplete#sources#omni#functions, 'javascript', [])
        call insert(g:neocomplete#sources#omni#functions.javascript, 'jspc#omni')
      endif

      " PHP
      if dein#tap('phpunit.vim')
        let g:neocomplete#sources#dictionary#dictionaries.php = $VIMFILES.'/dict/phpunit'
        Autocmd BufNewFile,BufRead *Test.php
          \ let b:neocomplete_sources = g:neocomplete#sources.javascript + ['dictionary']
      endif

      " Jest
      let g:neocomplete#sources#dictionary#dictionaries.javascript = $VIMFILES.'/dict/jest'
      Autocmd BufNewFile,BufRead *.{test,spec}.js
        \ let b:neocomplete_sources = g:neocomplete#sources.javascript + ['dictionary']
        \| let &l:dictionary = g:neocomplete#sources#dictionary#dictionaries.javascript
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:neocompleteOnSource'))
  endif

  if dein#tap('ultisnips')
    imap ` <Plug>(ultisnips)
    xmap ` <Plug>(ultisnipsVisual)
    snoremap <C-c> <Esc>

    inoremap <silent> <Plug>(ultisnips)        <C-r>=<SID>ultiComplete("\`")<CR>
    xnoremap <silent> <Plug>(ultisnipsVisual) :<C-u>call UltiSnips#SaveLastVisualSelection()<CR>gvs
    function! s:ultiComplete(key) abort
      if len(UltiSnips#SnippetsInCurrentScope()) >= 1
        let [curPos, lineLength] = [getcurpos()[4], col('$')]
        let isBackspace = getline('.')[curPos-2] =~ '\s'
        let isStartLine = curPos <= 1
        let isText = curPos <= lineLength
        if isText && !isStartLine && !isBackspace
          return UltiSnips#ExpandSnippet()
        endif
      endif
      return a:key
    endfunction

    function! s:ultiOnSource() abort
      let g:UltiSnipsEnableSnipMate = 0
      let g:UltiSnipsExpandTrigger = '<C-F12>'
      let g:UltiSnipsListSnippets = '<C-F12>'

      AutocmdFT twig  call UltiSnips#AddFiletypes('twig.html')
      AutocmdFT blade call UltiSnips#AddFiletypes('blade.html')
      Autocmd BufNewFile,BufReadPost *.snippets setlocal nowrap foldmethod=manual
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:ultiOnSource'))
  endif

  if dein#tap('vim-easymotion')
    nmap  s       <Plug>(easymotion-s)
    nmap ,s       <Plug>(easymotion-overwin-f)
    nmap ,S       <Plug>(easymotion-overwin-f2)
    nmap <Space>s <Plug>(easymotion-overwin-w)
    nmap <Space>S <Plug>(easymotion-overwin-line)
    nmap W        <Plug>(easymotion-lineforward)
    nmap B        <Plug>(easymotion-linebackward)

    map <expr> f getcurpos()[4] < col('$')-1 ? "\<Plug>(easymotion-fl)" : "\<Plug>(easymotion-Fl)"
    map <expr> F getcurpos()[4] <= 1         ? "\<Plug>(easymotion-fl)" : "\<Plug>(easymotion-Fl)"

    function! s:easymotionOnSource() abort
      let g:EasyMotion_verbose = 0
      let g:EasyMotion_do_mapping = 0
      let g:EasyMotion_show_prompt = 0
      let g:EasyMotion_startofline = 0
      let g:EasyMotion_space_jump_first = 1
      let g:EasyMotion_enter_jump_first = 1
    endfunction

    Autocmd ColorScheme,Syntax * call s:easymotionColors()
    function! s:easymotionColors() abort
      hi EasyMotionTarget       guifg=#2B2B2B guibg=#F6F7F7 gui=bold
      hi EasyMotionTarget2First guifg=#FF0000 guibg=#F6F7F7 gui=bold
      hi link EasyMotionShade         Comment
      hi link EasyMotionMoveHL        Search
      hi link EasyMotionIncCursor     Cursor
      hi link EasyMotionTarget2Second EasyMotionTarget
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:easymotionOnSource'))
  endif

  if dein#tap('denite.nvim')
    nnoremap <silent> ;g :<C-u>Denite grep<CR>
    nnoremap <silent> ;s :<C-u>Denite line     -mode=insert<CR>
    nnoremap <silent> ;v :<C-u>Denite line     -mode=insert -input=`expand('<lt>cword>')`<CR>
    nnoremap <silent> ;f :<C-u>Denite file_rec -mode=insert<CR>

    function! s:deniteOnSource() abort
      call denite#custom#option('default', 'prompt', ' ❯')
      call denite#custom#option('default', 'mode', 'normal')
      call denite#custom#option('default', 'statusline', v:false)

      " Sources
      call denite#custom#source('file_rec',                 'sorters',    ['sorter_sublime'])
      call denite#custom#source('line',                     'matchers',   ['matcher_regexp'])
      call denite#custom#source('file_mru',                 'matchers',   ['matcher_project_files', 'matcher_fuzzy'])
      call denite#custom#source('file_mru,file_rec,buffer', 'converters', ['converter_relative_word'])

      if executable('rg')
        " Ripgrep: https://github.com/BurntSushi/ripgrep
        call denite#custom#var('grep', 'command', ['rg'])
        call denite#custom#var('grep', 'recursive_opts', [])
        call denite#custom#var('grep', 'final_opts', ['.'])
        call denite#custom#var('grep', 'separator', ['--'])
        call denite#custom#var('grep', 'default_opts', ['--maxdepth', '8', '--vimgrep', '--no-heading'])
        call denite#custom#var('file_rec', 'command',  ['rg', '--maxdepth', '8', '-l', '.'])
      endif

      " Mappings
      call denite#custom#map('normal', '`',     '<denite:choose_action>',               'noremap')
      call denite#custom#map('normal', 'o',     '<denite:do_action:default>',           'noremap')
      call denite#custom#map('normal', '<Tab>', '<denite:enter_mode:insert>',           'noremap')
      call denite#custom#map('normal', '<C-j>', '<denite:scroll_window_downwards>',     'noremap')
      call denite#custom#map('normal', '<C-k>', '<denite:scroll_window_upwards>',       'noremap')
      call denite#custom#map('normal', 'Q',     '<denite:quit>',                        'noremap')
      call denite#custom#map('insert', 'C-i>',  '<denite:choose_action>',               'noremap')
      call denite#custom#map('insert', '<Tab>', '<denite:enter_mode:normal>',           'noremap')
      call denite#custom#map('insert', '<C-j>', '<denite:move_to_next_line>',           'noremap')
      call denite#custom#map('insert', '<C-k>', '<denite:move_to_prev_line>',           'noremap')
      call denite#custom#map('insert', '<C-p>', '<denite:paste_from_default_register>', 'noremap')
      call denite#custom#map('insert', '<A-j>', '<denite:scroll_window_downwards>',     'noremap')
      call denite#custom#map('insert', '<A-k>', '<denite:scroll_window_upwards>',       'noremap')
      call denite#custom#map('insert', '<C-d>', '<denite:delete_char_before_caret>',    'noremap')
      call denite#custom#map('insert', '<C-h>', '<denite:move_caret_to_left>',          'noremap')
      call denite#custom#map('insert', '<C-l>', '<denite:move_caret_to_right>',         'noremap')
      call denite#custom#map('insert', '<C-a>', '<denite:move_caret_to_head>',          'noremap')
      call denite#custom#map('insert', '<C-e>', '<denite:move_caret_to_tail>',          'noremap')
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:deniteOnSource'))
  endif

  if dein#tap('unite.vim')
    nnoremap <silent> `  :<C-u>Unite buffer -toggle<CR>
    nnoremap <silent> ;` :<C-u>Unite buffer -toggle -start-insert<CR>
    nnoremap <silent> ;b :<C-u>Unite buffer -toggle<CR>

    " Unite tuning
    AutocmdFT unite* setlocal nolist
    AutocmdFT unite* Autocmd InsertEnter,InsertLeave <buffer>
      \ setlocal nonu nornu nolist colorcolumn=

    AutocmdFT unite* call s:uniteMappings()
    function! s:uniteMappings() abort
      let b:unite = unite#get_current_unite()

      " unite-webcolorname
      if b:unite.buffer_name ==# 'colors'
        nmap <silent> <buffer> o <CR>
      endif

      " Normal mode
      nmap <buffer> e     <Nop>
      nmap <buffer> <BS>  <Nop>
      nmap <buffer> <C-k> <C-u>
      nmap <buffer> <C-e> <Plug>(unite_move_head)
      nmap <buffer> R     <Plug>(unite_redraw)
      nmap <buffer> <Tab> <Plug>(unite_insert_enter)<Right><Left>
      nmap <buffer> i     <Plug>(unite_insert_enter)<Right><Left>
      nmap <buffer> I     <Plug>(unite_insert_enter)<Plug>(unite_move_head)
      nmap <buffer> e     <Plug>(unite_toggle_mark_current_candidate)
      nmap <buffer> E     <Plug>(unite_toggle_mark_current_candidate_up)
      nmap <buffer> <C-o> <Plug>(unite_toggle_transpose_window)
      nmap <silent> <buffer> <nowait> <expr> o unite#do_action('open')
      nmap <silent> <buffer> <nowait> <expr> O unite#do_action('choose')
      nmap <silent> <buffer> <nowait> <expr> s unite#do_action('above')
      nmap <silent> <buffer> <nowait> <expr> S unite#do_action('below')
      nmap <silent> <buffer> <nowait> <expr> v unite#do_action('left')
      nmap <silent> <buffer> <nowait> <expr> V unite#do_action('right')
      nmap <silent> <buffer> <nowait> <expr> b unite#do_action('backup')
      nmap <silent> <buffer> <nowait> <expr> D unite#do_action('fdelete')
      nmap <silent> <buffer> <nowait> <expr> r
        \ b:unite.profile_name ==# 'line' ? unite#do_action('replace') : unite#do_action('rename')
      nmap <silent> <buffer> <nowait> <expr> R
        \ b:unite.profile_name ==# 'line' ? unite#do_action('replace') : unite#do_action('exrename')
      nmap <buffer> <expr> <C-x> unite#mappings#set_current_sorters(
        \ unite#mappings#get_current_sorters() ==# [] ? ['sorter_ftime', 'sorter_reverse'] : []) . "\<Plug>(unite_redraw)"

      " Insert mode
      imap <buffer> <C-e>   <End>
      imap <buffer> <C-a>   <Plug>(unite_move_head)
      imap <buffer> <C-j>   <Plug>(unite_move_left)
      imap <buffer> <C-l>   <Plug>(unite_move_right)
      imap <buffer> <Tab>   <Plug>(unite_insert_leave)
      imap <buffer> <S-Tab> <Plug>(unite_complete)
      imap <buffer> <C-j>   <Plug>(unite_select_next_line)
      imap <buffer> <C-k>   <Plug>(unite_select_previous_line)
      imap <buffer> <C-o>   <Plug>(unite_toggle_transpose_window)
      imap <buffer> <expr> <C-h>  col('$') > 2 ? "\<Plug>(unite_delete_backward_char)" : ""
      imap <buffer> <expr> <BS>   col('$') > 2 ? "\<Plug>(unite_delete_backward_char)" : ""
      imap <buffer> <expr> <S-BS> col('$') > 2 ? "\<Plug>(unite_delete_backward_word)" : ""
      imap <buffer> <expr> q      getline('.')[getcurpos()[4]-2] ==# 'q' ? "\<Plug>(unite_exit)" : "\q"
      imap <buffer> <expr> <C-x> unite#mappings#set_current_sorters(
        \ unite#mappings#get_current_sorters() == [] ? ['sorter_ftime', 'sorter_reverse'] : []
        \) . col('$') > 2 ? "" : "\<Plug>(unite_delete_backward_word)"
    endfunction

    function! s:uniteOnSource() abort
      let g:unite_source_buffer_time_format = '%H:%M '
      let g:unite_data_directory = $CACHE.'/unite'

      " Context
      let default = {
        \ 'winheight': 20,
        \ 'direction': 'belowright',
        \ 'prompt_direction': 'bellow',
        \ 'cursor_line_time': '0.0',
        \ 'short_source_names': 1,
        \ 'hide_source_names': 1,
        \ 'hide_icon': 0,
        \ 'marked_icon': '+',
        \ 'prompt': '>',
        \ 'wipe': 1
        \}
      let quickfix = {
        \ 'winheight': 16,
        \ 'keep_focus': 1,
        \ 'no_quit': 1
        \}

      " Profiles
      call unite#custom#profile('default', 'context', default)
      call unite#custom#profile('quickfix', 'context', quickfix)
      " Filters
      call unite#custom#source('buffer', 'converters', ['converter_uniq_word', 'converter_word_abbr'])
    endfunction

    Autocmd Syntax unite call s:uniteColors()
    function! s:uniteColors() abort
      hi link uniteStatusHead             StatusLine
      hi link uniteStatusNormal           StatusLine
      hi link uniteStatusMessage          StatusLine
      hi link uniteStatusSourceNames      StatusLine
      hi link uniteStatusSourceCandidates User1
      hi link uniteStatusLineNR           User2
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:uniteOnSource'))
  endif

  if dein#tap('vim-qfreplace')
    AutocmdFT qfreplace* nested call s:qfreplaceBuffer()

    " qfreplace tuning
    function! s:qfreplaceBuffer() abort
      call feedkeys("\<CR>\<Esc>")
      setlocal nonu nornu colorcolumn= laststatus=0
      Autocmd BufEnter,WinEnter <buffer> setlocal laststatus=0
      Autocmd BufLeave,BufDelete <buffer> set laststatus=2
      Autocmd InsertEnter,InsertLeave <buffer> setlocal nonu nornu colorcolumn=
    endfunction
  endif

" File-types
"---------------------------------------------------------------------------
" Rust
  Autocmd BufNewFile,BufRead *.rt setlocal filetype=rust

" Haskell
  AutocmdFT haskell setlocal nowrap textwidth=120 | Indent 4
  AutocmdFT haskell setlocal cpoptions+=M
  if dein#tap('ghcmod-vim')
    AutocmdFT haskell
      \  nnoremap <silent> <buffer> ;t :<C-u>GhcModType!<CR>
      \| nnoremap <silent> <buffer> ;T :<C-u>GhcModTypeClear<CR>

    AutocmdFT haskell Autocmd BufWritePost <buffer> GhcModCheckAndLintAsync

    function! s:ghcmodQuickFix() abort
      Unite quickfix -no-empty -silent
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source',
      \ "'let g:ghcmod_open_quickfix_function = 's:ghcmodQuickFix'")
  endif

" PHP
  Autocmd BufNewFile,BufRead *.php let b:did_ftplugin = 1
  " Indent
  AutocmdFT php setlocal nowrap textwidth=120 | Indent 4
  " Syntax
  AutocmdFT php let [g:php_sql_query, g:php_highlight_html] = [1, 1]
  " Autocomplete
  AutocmdFT php setlocal omnifunc=phpcomplete#CompletePHP

  if dein#tap('phpunit.vim')
    AutocmdFT php call s:phpunitMappings()

    function! s:phpunitMappings() abort
      for char in split('ta tf ts')
        execute printf('silent! iunmap %s', char)
      endfor | unlet char

      nnoremap <silent> <buffer> ,T :<C-u>PHPUnitRunAll<CR>
      nnoremap <silent> <buffer> ,t :<C-u>PHPUnitRunCurrentFile<CR>
      " nnoremap <silent> <buffer> ,f :<C-u>PHPUnitRunFilter<CR>
    endfunction

    Autocmd Syntax phpunit call s:phpunitColors()
    function! s:phpunitColors() abort
      hi link PHPUnitOK         Todo
      hi link PHPUnitFail       WarningMsg
      hi link PHPUnitAssertFail Error
    endfunction
  endif

" JavaScript
  Autocmd BufNewFile,BufRead *.{jsx,es6} setlocal filetype=javascript
  " Indent
  AutocmdFT javascript setlocal nowrap textwidth=120 | Indent 2

" Jest
  AutocmdFT jest Autocmd Syntax jest call s:jestColors()
  function! s:jestColors() abort
    syntax match jestPass /\vPASS/
    syntax match jestFail /\vFAIL/
    hi link jestPass Todo
    hi link jestFail WarningMsg
  endfunction

  if dein#tap('vim-jsdoc')
    let g:jsdoc_enable_es6 = 1
    let g:jsdoc_allow_input_prompt = 0
    let g:jsdoc_access_descriptions = 2
    let g:jsdoc_custom_args_hook = {
      \ '^e$':          {'type': ' {Event} '},
      \ 'str':          {'type': ' {String} '},
      \ '^arr$':        {'type': ' {Array} '},
      \ '^(i\|n)$':     {'type': ' {Number} '},
      \ '^(o\|obj)$':   {'type': ' {Object} '},
      \ '^(fn\|cb)$':   {'type': ' {Function} '},
      \ '^(el\|node)$': {'type': ' {Element} '},
      \ 'callback\|cb': {'type': ' {Function} ', 'description': 'Callback function'}
      \}

    AutocmdFT javascript
      \  nmap <buffer> ,c <Plug>(jsdoc)
      \| nmap <silent> <buffer> ,C ?function<CR>:nohlsearch<CR><Plug>(jsdoc)
  endif

" HTML
  " Indent
  AutocmdFT html setlocal textwidth=120 | Indent 2
  " Syntax
  if dein#tap('MatchTag')
    AutocmdFT php
      \ Autocmd BufWinEnter <buffer> call s:removeMatchTagEvent()

    function! s:removeMatchTagEvent() abort
      if !exists('#matchhtmlparen') | return | endif
      augroup matchhtmlparen
        autocmd! * <buffer>
      augroup END
    endfunction
  endif
  " Autocomplete
  if dein#tap('emmet-vim')
    AutocmdFT html,twig call s:emmetMappings()

    function! s:emmetMappings() abort
      imap <silent> <buffer> <Tab> <C-r>=<SID>emmetComplete("\<Tab>")<CR>
    endfunction

    function! s:emmetComplete(key) abort
      if pumvisible()
        return "\<C-n>"
      endif
      if emmet#isExpandable()
        let isBackspace = getline('.')[getcurpos()[4]-2] =~ '\s'
        if !isBackspace
          return emmet#expandAbbr(0, '')
        endif
      endif
      if exists('*s:neoComplete')
        return <SID>neoComplete(a:key)
      endif
      return a:key
    endfunction
  endif

" Twig
  Autocmd BufNewFile,BufRead *.{twig,*.twig} setlocal filetype=twig
  " Autocomplete
  AutocmdFT twig setlocal omnifunc=htmlcomplete#CompleteTags
  " Indent
  AutocmdFT twig setlocal textwidth=120 | Indent 2
  " Syntax
  AutocmdFT twig setlocal commentstring={#<!--%s-->#}

  if dein#tap('twig.vim')
    Autocmd Syntax twig call s:twigColors()
    function! s:twigColors() abort
      hi twigVariable  guifg=#2B2B2B gui=bold
      hi twigStatement guifg=#008080 gui=NONE
      hi twigOperator  guifg=#999999 gui=NONE
      hi link twigBlockName twigVariable
      hi link twigVarDelim  twigOperator
      hi link twigTagDelim  twigOperator
    endfunction
  endif

" Blade
  Autocmd BufNewFile,BufRead *.blade.php setlocal filetype=blade
  " Indent
  AutocmdFT blade setlocal textwidth=120 | Indent 2
  " Syntax
  AutocmdFT blade setlocal commentstring={{--%s--}}

  if dein#tap('vim-blade')
    Autocmd Syntax blade call s:bladeColors()
    function! s:bladeColors() abort
      hi bladeEcho          guifg=#2B2B2B gui=bold
      hi bladeKeyword       guifg=#008080 gui=NONE
      hi bladePhpParenBlock guifg=#999999 gui=NONE
      hi link bladeDelimiter phpParent
      " Reset SQL syntax
      hi link sqlStatement phpString
      hi link sqlKeyword   phpString
    endfunction
  endif

" CSS
  AutocmdFT css setlocal nonumber norelativenumber
  " Indent
  AutocmdFT css setlocal nowrap | Indent 2
  " Syntax
  AutocmdFT css setlocal iskeyword+=-,%,:

  if dein#tap('css.vim')
    Autocmd Syntax css call s:cssColors()
    function! s:cssColors() abort
      hi link cssError Normal
      hi link cssBraceError Normal
      hi link cssDeprecated Normal
    endfunction
  endif

  " Autocomplete
  if dein#tap('vim-hyperstyle')
    AutocmdFT css,sass,scss,sss,sugarss call s:hyperstyleSettings()
    function! s:hyperstyleSettings() abort
      let b:hyperstyle = 1
      let b:hyperstyle_semi = ''
      imap <buffer> <expr> <S-CR>
        \ getline('.')[getcurpos()[4] - 2] =~# '[0-9; ]' ? "\<Space>" : "\<Space>\<Plug>(hyperstyle-tab)"
    endfunction
  endif

" SASS
  Autocmd BufNewFile,BufRead *.scss
    \ setlocal filetype=css syntax=sass commentstring=//%s
  " Syntax
  Autocmd Syntax sass
    \ hi sassClass guifg=#2B2B2B guibg=#F6F7F7 gui=bold

" Sugar CSS
  " Autocomplete
  AutocmdFT sugarss setlocal omnifunc=csscomplete#CompleteCSS

" JSON
  Autocmd BufNewFile,BufRead .{babelrc,eslintrc} setlocal filetype=json
  " Indent
  AutocmdFT json setlocal nonu nornu | Indent 2
    \| Autocmd BufNewFile,BufRead <buffer> setlocal formatoptions+=2l

  if dein#tap('vim-json')
    AutocmdFT json
      \ nnoremap <silent> <buffer> ,c :<C-u>let &l:conceallevel = (&l:conceallevel ==# 0 ? 2 : 0)<CR>
        \:echo printf(' Conceal mode: %3S (local)', (&l:conceallevel ==# 0 ? 'Off' : 'On'))<CR>

    Autocmd Syntax json
      \ syntax match jsonComment "//.\{-}$" | hi link jsonComment Comment
  endif

" XML
  Autocmd BufNewFile,BufRead *.{xml,xml.*} setlocal filetype=xml
  " Indent
  AutocmdFT xml setlocal nowrap | Indent 2
  " Syntax
  Autocmd Syntax xml hi link xmlError xmlTag

" Yaml
  AutocmdFT yaml setlocal nowrap | Indent 2

" Vagrant
  Autocmd BufNewFile,BufRead Vagrantfile setlocal filetype=ruby

" Vim
  AutocmdFT vim setlocal iskeyword+=: | Indent 2

" GUI
"---------------------------------------------------------------------------
  if has('gui_running')
    if has('vim_starting')
      winsize 190 34 | winpos 492 350
    endif
    set guioptions=ac
    set guicursor=a:blinkon0  " turn off blinking the cursor
    set linespace=4           " extra spaces between rows

    if IsWindows()
      set guifont=Droid_Sans_Mono:h10,Consolas:h11
    else
      set guifont=Droid\ Sans\ Mono\ 10,Consolas\ 11
    endif

    " DirectWrite
    if IsWindows() && has('directx')
      set renderoptions=type:directx,gamma:2.2,contrast:0.5,level:0.5,geom:1,renmode:3,taamode:2
    endif
  endif

" View
"---------------------------------------------------------------------------
  if !exists('g:syntax_on') | syntax on | endif
  " Don't override colorscheme on reloading
  if !exists('g:colors_name')
    silent! colorscheme mild
    " Reload the colorscheme whenever we write the file
    execute 'Autocmd BufWritePost '. g:colors_name '.vim colorscheme '. g:colors_name
  endif

  set shortmess=aoOtTIcF
  set number relativenumber    " show the line number
  set nocursorline             " highlight the current line
  set noequalalways            " resize windows as little as possible
  set showtabline=0            " always show the tab pages
  set hidden                   " allows the closing of buffers without saving
  set switchbuf=useopen,split  " orders to open the buffer
  set winminheight=0
  set splitbelow splitright

  " Wrapping
  if exists('+breakindent')
    set wrap                         " wrap long lines
    set linebreak                    " wrap without line breaks
    set breakindent                  " wrap lines, taking indentation into account
    set breakindentopt=shift:4       " indent broken lines
    set breakat=\ \ ;:,!?            " break point for linebreak
    set textwidth=0                  " do not wrap text
    set display+=lastline            " easy browse last line with wrap text
    set whichwrap=<,>,[,],h,l,b,s,~  " end/beginning-of-line cursor wrapping behave human-like
  else
    set nowrap
    set sidescroll=1
  endif

  " Folding
  set nofoldenable
  " Diff
  set diffopt=filler,iwhite,vertical

  " Highlight invisible symbols
  set nolist listchars=precedes:<,extends:>,nbsp:.,tab:+-,trail:•
  " Avoid showing trailing whitespace when in Insert mode
  let s:trailchar = matchstr(&listchars, '\(trail:\)\@<=\S')
  Autocmd InsertEnter * execute 'setlocal listchars+=trail:' . s:trailchar
  Autocmd InsertLeave * execute 'setlocal listchars-=trail:' . s:trailchar

  " Title-line
  set title titlestring=%t%(\ %M%)%(\ (%{expand(\"%:~:.:h\")})%)%(\ %a%)

  " Command-line
  set cmdheight=1
  set noshowmode   " don't show the mode ('-- INSERT --') at the bottom
  set wildmenu wildmode=longest,full

" Edit
"---------------------------------------------------------------------------
  " Keymapping timeout (mapping / keycode)
  set notimeout ttimeoutlen=100

  set report=0           " reporting number of lines changes
  set lazyredraw         " don't redraw while executing macros
  set nostartofline      " avoid moving cursor to BOL when jumping around
  set virtualedit=all    " allows the cursor position past true end of line
  " set clipboard=unnamed  " use * register for copy-paste

  " Indent
  set cindent          " smart indenting for c-like code
  set autoindent       " indent at the same level of the previous line
  set shiftround       " indent multiple of shiftwidth
  set expandtab        " spaces instead of tabs
  set tabstop=2        " number of spaces per tab for display
  set shiftwidth=2     " number of spaces per tab in insert mode
  set softtabstop=2    " number of spaces when indenting
  set nojoinspaces     " prevents inserting two spaces after punctuation on a join (J)
  set backspace=indent,eol,start

  " Search
  set smartcase
  set ignorecase
  set hlsearch         " highlight search results
  set incsearch        " find as you type search
  set gdefault         " flag 'g' by default for replacing
  set magic            " change the way backslashes are used in search patterns

  " Autocomplete
  set pumheight=10
  set complete=. completeopt=longest
  " Syntax complete if nothing else available
  Autocmd BufEnter,WinEnter * if &omnifunc ==# '' | setlocal omnifunc=syntaxcomplete#Complete | endif

source $VIMFILES/statusline.vim
source $VIMFILES/abbr.vim
source $VIMFILES/mapping.vim
