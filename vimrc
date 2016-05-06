" .vimrc / 2016 May
" Author: Alex Masterov <alex.masterow@gmail.com>
" Source: https://github.com/AlexMasterov/vimfiles

" Environment
"---------------------------------------------------------------------------
  set noexrc          " avoid reading local (g)vimrc, exrc
  set modelines=0     " prevents security exploits
  " Vimfiles
  let $VIMFILES = expand('$VIM/vimfiles')
  let $CACHE = expand('$VIMFILES/cache')
  let &viminfo = '200,<1000,s10,no h,rA:,rB:,n'. expand('$VIMFILES/viminfo')

  " Initialize autogroup in MyVimrc
  augroup MyVimrc | execute 'autocmd!' | augroup END

  " Echo startup time on start
  if has('vim_starting') && has('reltime')
    " Shell: vim --startuptime filename -q; vim filename
    " vim --cmd 'profile start profile.txt' --cmd 'profile file $HOME/.vimrc' +q && vim profile.txt
    let s:startuptime = reltime()
    autocmd MyVimrc VimEnter * let s:startuptime = reltime(s:startuptime) | redraw
                    \| echomsg ' startuptime:'. reltimestr(s:startuptime)
  endif

" Commands
"---------------------------------------------------------------------------
  command! -nargs=* Autocmd   autocmd MyVimrc <args>
  command! -nargs=* AutocmdFT autocmd MyVimrc FileType <args>
  command! -nargs=1 Indent
    \ execute 'setlocal tabstop='.<q-args> 'softtabstop='.<q-args> 'shiftwidth='.<q-args>

" Events
"---------------------------------------------------------------------------
  Autocmd BufWritePost $MYVIMRC | source $MYVIMRC | redraw
  " Remove quit command from history
  Autocmd VimEnter * call histdel(':', '^w\?q\%[all]!\?$')
  Autocmd VimEnter * filetype plugin indent on
  " Toggle settings between modes
  Autocmd InsertEnter * setlocal list
  Autocmd InsertLeave * setlocal nolist
  Autocmd WinLeave * setlocal nornu
  Autocmd WinEnter * let [&l:nu, &l:rnu] = &l:nu ? [1, 1] : [&l:nu, &l:rnu]

" Functions
"---------------------------------------------------------------------------
  " Strip trailing whitespace
  Autocmd BufWritePre,FileWritePre * call s:trimWhiteSpace()
  command! -nargs=* -complete=file TrimWhiteSpace f <args> | call s:trimWhiteSpace()

  function! s:trimWhiteSpace() abort
    if &binary | return | endif
    let [winView, _s] = [winsaveview(), @/]
    silent %s/\s\+$//ge
    call winrestview(winView) | let @/=_s
  endfunction

  " Create a directory
  Autocmd BufWritePre,FileWritePre * call s:makeDir('<afile>:p:h', v:cmdbang)
  command! -nargs=1 -bang Mkdir call s:makeDir(<f-args>, "<bang>")

  function! s:makeDir(dir, ...) abort
    let force = a:0 >= 1 && a:1 ==# '!'
    let dir = expand(a:dir, 1)
    if !isdirectory(dir)
      \ && (force || input(printf('"%s" does not exist. Create? [yes/no]', dir)) =~? '^y\%[es]$')
      silent call mkdir(iconv(dir, &encoding, &termencoding), 'p')
    endif
  endfunction

  " Detect Windows OS
  let s:is_windows = has('win32') || has('win64')

  function! IsWindows() abort
    return s:is_windows
  endfunction

" Encoding
"---------------------------------------------------------------------------
  set encoding=utf-8
  scriptencoding utf-8

  if IsWindows() && has('multi_byte')
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
  " Cache
  Mkdir! $CACHE
  set directory=$VIMFILES/tmp
  set noswapfile
  " Undo
  Mkdir! $VIMFILES/undo
  set undodir=$VIMFILES/undo
  set undofile undolevels=500 undoreload=1000
  " View
  set viewdir=$VIMFILES/views
  set viewoptions=cursor,slash,unix

  " Russian keyboard
  set iskeyword=@,48-57,_,192-255
  set keymap=russian-jcukenwin
  if has('multi_byte')
    set iminsert=0 imsearch=0
  endif

  if exists('&regexpengine')
    " Regexp engine (0=auto, 1=old, 2=NFA)
    set regexpengine=2
  endif

" Plugins
"---------------------------------------------------------------------------
  " Avoid loading same default plugins
  let g:loaded_gzip = 1
  let g:loaded_zipPlugin = 1
  let g:loaded_tarPlugin = 1
  let g:loaded_logipat = 1
  let g:loaded_rrhelper = 1
  let g:loaded_matchparen = 1
  let g:loaded_netrwPlugin = 1
  let g:loaded_2html_plugin = 1
  let g:loaded_vimballPlugin = 1
  let g:loaded_getscriptPlugin = 1
  let g:loaded_spellfile_plugin = 1
  let g:did_install_default_menus = 1

  " Setup Dein plugin manager
  if has('vim_starting')
    let s:deinPath = expand('$VIM/dein')
    let s:deinRepo = expand(s:deinPath.'/repos/github.com/Shougo/dein.vim')
    if !isdirectory(s:deinRepo)
      if executable('git')
        let s:deinUri = 'https://github.com/Shougo/dein.vim.git'
        call system(printf('git clone --depth 1 %s %s', s:deinUri, s:deinRepo))
      else
        echom 'Can`t download Dein: Git not found.'
      endif
    endif
    execute 'set runtimepath='. s:deinRepo .','. $VIMRUNTIME
  endif

  if dein#load_state(s:deinPath)
    call dein#begin(s:deinPath, [expand('<sfile>')])

    " Load develop version plugins
    call dein#local($VIMFILES.'/dev', {
      \ 'frozen': 1,
      \ 'merged': 0
      \}, ['dotvim', 'gist'])

    " Gist
    call dein#add('https://gist.github.com/AlexMasterov/e81093a7b4cf14413b2b04abcf83ffe2', {
      \ 'script_type': 'plugin',
      \ 'on_func': 'CleanBuffers',
      \ 'hook_add': "Autocmd BufHidden * call CleanBuffers('!')",
      \ 'hook_source': 'let g:bufcleaner_max_saved = 9'
      \})

    call dein#add('Shougo/dein.vim', {
      \ 'rtp': '',
      \ 'hook_add': join([
      \   'let g:dein#types#git#clone_depth = 1',
      \   'let g:dein#install_max_processes = 16',
      \   'nnoremap <silent> ;u :<C-u>call dein#update()<CR>',
      \   'nnoremap <silent> ;i :<C-u>call dein#install()<CR>'
      \], "\n")
      \})
    call dein#add('Shougo/vimproc.vim', {
      \ 'lazy': 1,
      \ 'build': IsWindows() ? 'tools\\update-dll-mingw' : 'make'
      \})
    call dein#add('kopischke/vim-stay', {
      \ 'on_path': '.*'
      \})
    call dein#add('Shougo/vimfiler.vim', {
      \ 'on_if': "isdirectory(bufname('%'))",
      \ 'on_cmd': ['VimFiler', 'VimFilerCurrentDir'],
      \ 'on_map': [['n', '<Plug>']]
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
      \   'let g:caw_hatpos_skip_blank_line = 1'
      \], "\n"),
      \})
    call dein#add('kana/vim-smartchr')
    call dein#add('easymotion/vim-easymotion', {
      \ 'on_map': [['nx', '<Plug>(easymotion-']]
      \})
    call dein#add('haya14busa/vim-keeppad', {
      \ 'on_cmd': ['KeeppadOn', 'KeeppadOff'],
      \ 'hook_add': 'Autocmd BufReadPre *.{css,sss,json},qfreplace* KeeppadOn',
      \ 'hook_source': 'let g:keeppad_autopadding = 0'
      \})
    call dein#add('lilydjwg/colorizer', {
      \ 'on_cmd': ['ColorToggle', 'ColorHighlight', 'ColorClear'],
      \ 'hook_source': 'let g:colorizer_nomap = 1'
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
    call dein#add('junegunn/vim-easy-align', {
      \ 'on_map': [['nx', '<Plug>(EasyAlign)']],
      \ 'hook_add': 'vmap <Enter> <Plug>(EasyAlign)'
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
    call dein#add('AndrewRadev/splitjoin.vim', {
      \ 'on_cmd': 'SplitjoinSplit',
      \ 'hook_add': 'nmap <silent> S :<C-u>SplitjoinSplit<CR><CR><Esc>'
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
    call dein#add('jakobwesthoff/argumentrewrap', {
      \ 'hook_add': 'map <silent> K :<C-u>call argumentrewrap#RewrapArguments()<CR>'
      \})
    call dein#add('gcmt/wildfire.vim', {
      \ 'on_map': [['nx', '<Plug>(wildfire-']],
      \ 'hook_add': join([
      \   'nmap vv    <Plug>(wildfire-fuel)',
      \   'xmap vv    <Plug>(wildfire-fuel)',
      \   'xmap <C-v> <Plug>(wildfire-water)'
      \], "\n"),
      \ 'hook_source': "let g:wildfire_objects = {'*': split('iw iW i' i\" i) a) a] a}'), 'html,xml,twig,blade': ['at']}"
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
    call dein#add('triglav/vim-visual-increment', {
      \ 'on_map': [['x', '<Plug>Visual']],
      \ 'hook_add': join([
      \   'xmap <C-a> <Plug>VisualIncrement',
      \   'xmap <C-x> <Plug>VisualDecrement'
      \], "\n"),
      \ 'hook_source': 'set nrformats+=alpha'
      \})

    call dein#add('cohama/agit.vim', {
      \ 'if': executable('git'),
      \ 'on_cmd': ['Agit', 'AgitFile'],
      \ 'hook_add': join([
      \   'nnoremap <silent> ,gg :<C-u>Agit<CR>',
      \   'nnoremap <silent> ,gf :<C-u>AgitFile<CR>'
      \], "\n"),
      \ 'on_source': 'let g:agit_max_log_lines = 100'
      \})
    call dein#add('lambdalisue/vim-gita', {
      \ 'if': executable('git'),
      \ 'on_cmd': 'Gita',
      \ 'hook_add': join([
      \   'nnoremap <silent> ,,   :<C-u>Gita status<CR>',
      \   'nnoremap <silent> ,gs  :<C-u>Gita status<CR>',
      \   'nnoremap <silent> ,gi  :<C-u>Gita init<CR>',
      \   'nnoremap <silent> ,gb  :<C-u>Gita branch<CR>',
      \   'nnoremap <silent> ,gc  :<C-u>Gita commit<CR>',
      \   'nnoremap <silent> ,gca :<C-u>Gita commit --amend<CR>'
      \], "\n")
      \})

    call dein#add('dylanaraps/root.vim', {
      \ 'on_cmd': 'Root',
      \ 'hook_add': 'Autocmd BufNewFile,BufRead,BufEnter,WinEnter,BufWinEnter * Root',
      \ 'hook_source': join([
      \   'let g:root#auto = 0',
      \   'let g:root#echo = 0',
      \   'let g:root#patterns ='
      \   . "split('.git .git/ .hg .hg/ composer.json package.json .tern-project docker-compose.yml phpunit.xml.dist')"
      \], "\n")
      \})

    call dein#add('Shougo/context_filetype.vim', {
      \ 'hook_add': 'let g:context_filetype#search_offset = 500'
      \})
    call dein#add('Shougo/neocomplete.vim', {
      \ 'depends': 'context_filetype.vim',
      \ 'on_event': 'InsertEnter'
      \})
    call dein#add('Shougo/neco-syntax')
    call dein#add('Shougo/neoinclude.vim', {
      \ 'on_source': 'neocomplete.vim'
      \})

    call dein#add('SirVer/ultisnips', {
      \ 'on_event': 'InsertCharPre',
      \ 'on_func': 'UltiSnips#FileTypeChanged',
      \ 'hook_source': 'Autocmd VimEnter * silent! au! UltiSnipsFileType'
      \})

    " Unite
    call dein#add('Shougo/unite.vim', {'lazy': 1})
    call dein#add('chemzqm/unite-location')
    call dein#add('thinca/vim-qfreplace', {
      \ 'on_source': 'unite.vim'
      \})
    call dein#add('Shougo/unite-outline', {
      \ 'hook_add': 'nnoremap <silent> ;o :<C-u>Unite outline -silent -no-empty -toggle -winheight=16<CR>'
      \})
    call dein#add('mattn/httpstatus-vim', {
      \ 'on_source': 'unite.vim',
      \ 'hook_add': 'nnoremap <silent> <F12> :<C-u>Unite httpstatus -start-insert<CR>'
      \})
    call dein#add('osyo-manga/unite-vimpatches', {
      \ 'hook_add': 'nnoremap <silent> ;U :<C-u>Unite vimpatches -buffer-name=dein<CR>'
      \})
    call dein#add('Shougo/neomru.vim', {
      \ 'on_source': 'unite.vim',
      \ 'on_path': '.*',
      \ 'on_cmd': ['NeoMRUSave', 'NeoMRUReload'],
      \ 'hook_add': 'Autocmd BufWipeout,BufLeave,WinLeave,BufWinLeave,VimLeavePre * NeoMRUSave',
      \ 'hook_source': join([
      \   "let g:neomru#file_mru_path = $CACHE.'/unite/file'",
      \   "let g:neomru#file_mru_ignore_pattern = '\.\%([_]vimrc\|txt\)$\|\gita.*'",
      \   "let g:neomru#filename_format = ':.'",
      \   "let g:neomru#directory_mru_path = $CACHE.'/unite/directory'",
      \   "let g:neomru#time_format = '%d.%m %H:%M — '",
      \   "call unite#custom#source('neomru/file,neomru/directory', 'limit', 20)"
      \], "\n")
      \})

    " Task Runner
    call dein#add('thinca/vim-quickrun', {
      \ 'depends': 'vimproc.vim',
      \ 'on_func': 'quickrun#',
      \ 'on_cmd': 'QuickRun',
      \ 'on_map': [['n', '<Plug>(quickrun)']]
      \})
    " vim-quickrun bundles
    call dein#local($VIMFILES.'/dev', {
      \ 'frozen': 1,
      \ 'merged': 0
      \}, ['quickrun'])

    " Operators
    call dein#add('kana/vim-operator-user')
    call dein#add('kana/vim-operator-replace', {
      \ 'depends': 'vim-operator-user',
      \ 'on_map': [['nx', '<Plug>(operator-replace)']],
      \ 'hook_add': join([
      \   'nmap R <Plug>(operator-replace)',
      \   'vmap R <Plug>(operator-replace)'
      \], "\n")
      \})
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
    call dein#add('haya14busa/vim-operator-flashy', {
      \ 'depends': 'vim-operator-user',
      \ 'on_map': [['n', '<Plug>(operator-flashy)']],
      \ 'hook_add': join([
      \   'nmap y <Plug>(operator-flashy)',
      \   'nmap Y <Plug>(operator-flashy)$'
      \], "\n"),
      \ 'hook_source': join([
      \   "let g:operator#flashy#group = 'Visual'",
      \   'let g:operator#flashy#flash_time = 280'
      \], "\n")
      \})
    call dein#add('kusabashira/vim-operator-eval', {
      \ 'depends': 'vim-operator-user',
      \ 'on_map': [['v', '<Plug>(operator-eval-']],
      \ 'hook_add': 'vmap <silent> se <Plug>(operator-eval-vim)'
      \})

    " Text-objects
    call dein#add('kana/vim-textobj-user')
    call dein#add('machakann/vim-textobj-delimited', {
      \ 'depends': 'vim-textobj-user',
      \ 'on_map': ['vid', 'viD', 'vad', 'vaD']
      \})
    call dein#add('whatyouhide/vim-textobj-xmlattr', {
      \ 'depends': 'vim-textobj-user',
      \ 'on_map': ['vix', 'vax']
      \})

    " Rust
    call dein#add('rust-lang/rust.vim', {
      \ 'on_ft': 'rust',
      \ 'hook_source': join([
      \   'let g:rustfmt_autosave = 0',
      \   "let g:ftplugin_rust_source_path = exists('$RUST_SRC_PATH') ? $RUST_SRC_PATH : ''"
      \], "\n")
      \})
    call dein#add('ebfe/vim-racer', {
      \ 'if': executable('racer'),
      \ 'hook_add': join([
      \   'AutocmdFT rust setlocal omnifunc=racer#Complete',
      \   'AutocmdFT rust nnoremap <silent> <buffer> gd :<C-u>call racer#JumpToDefinition()<CR>'
      \], "\n")
      \})

    " Haskell
    call dein#add('itchyny/vim-haskell-indent')
    call dein#add('Twinside/vim-syntax-haskell-cabal')
    call dein#add('eagletmt/ghcmod-vim', {
      \ 'on_cmd': ['GhcModCheck', 'GhcModLint', 'GhcModCheckAndLintAsync']
      \})
    call dein#add('eagletmt/neco-ghc', {
      \ 'hook_add': 'AutocmdFT haskell setlocal omnifunc=necoghc#omnifunc',
      \ 'hook_source': 'let g:necoghc_enable_detailed_browse = 1'
      \})

    " PHP
    call dein#add('2072/PHP-Indenting-for-VIm')
    call dein#add('shawncplus/phpcomplete.vim', {
      \ 'hook_add': join([
      \   'let g:phpcomplete_relax_static_constraint = 0',
      \   'let g:phpcomplete_parse_docblock_comments = 0',
      \   'let g:phpcomplete_search_tags_for_variables = 1',
      \   'let g:phpcomplete_complete_for_unknown_classes = 0',
      \   "let g:phpcomplete_remove_function_extensions = split('apache dba dbase odbc msql mssql')",
      \   "let g:phpcomplete_remove_constant_extensions = split('ms_sql_server_pdo msql mssql')"
      \], "\n")
      \})
    call dein#add('c9s/phpunit.vim', {
      \ 'on_cmd': 'PHPUnit',
      \ 'hook_add': "AutocmdFT phpunit let &l:statusline = ' '"
      \})
    call dein#add('tobyS/vmustache', {
      \ 'depends': 'vmustache'
      \})
    call dein#add('tobyS/pdv', {
      \ 'hook_add': 'AutocmdFT php nnoremap <silent> <buffer> ,c :<C-u>silent! call pdv#DocumentWithSnip()<CR>',
      \ 'hook_source': "let g:pdv_template_dir = $VIMFILES.'/dev/dotvim/templates'"
      \})
    call dein#add('arnaud-lb/vim-php-namespace', {
      \ 'on_func': 'PhpSortUse',
      \ 'hook_add': join([
      \   'AutocmdFT php nnoremap <silent> <buffer> ;x :<C-u>call PhpSortUse()<CR>'
      \], "\n")
      \})

    " Blade
    call dein#add('jwalton512/vim-blade')

    " Twig
    call dein#add('tokutake/twig-indent')
    call dein#local($VIMFILES.'/dev', {
      \ 'frozen': 1,
      \ 'merged': 0,
      \ 'hook_add': 'AutocmdFT twig '
      \ . 'Autocmd BufNewFile,BufRead,BufEnter,WinEnter <buffer> runtime! syntax/html.vim'
      \}, ['twig.vim'])

    " JavaScript
    call dein#add('othree/jspc.vim')
    call dein#add('gavocanov/vim-js-indent')
    call dein#add('othree/jsdoc-syntax.vim')
    call dein#add('heavenshell/vim-jsdoc', {
      \ 'hook_add': join([
      \   'AutocmdFT javascript nmap <buffer> ,c <Plug>(jsdoc)',
      \   'AutocmdFT javascript nmap <silent> <buffer> ,C ?function<CR>:noh<CR><Plug>(jsdoc)',
      \], "\n"),
      \ 'hook_source': join([
      \   'let g:jsdoc_enable_es6 = 1',
      \   'let g:jsdoc_allow_input_prompt = 1',
      \   'let g:jsdoc_input_description = 1',
      \   'let g:jsdoc_additional_descriptions = 0',
      \   'let g:jsdoc_return_description = 0'
      \], "\n")
      \})

    " CSS
    call dein#add('JulesWang/css.vim')
    call dein#add('hail2u/vim-css3-syntax')
    call dein#add('othree/csscomplete.vim')

    " SVG
    call dein#add('aur-archive/vim-svg')
    call dein#add('jasonshell/vim-svg-indent')

    " JSON
    call dein#add('elzr/vim-json', {
      \ 'hook_source': join([
      \   'let g:vim_json_warnings = 0',
      \   "let g:vim_json_syntax_concealcursor = 'n'"
      \], "\n")
      \})

    " CSV
    call dein#add('chrisbra/csv.vim')

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
        \ '>': {'pattern': '>>\|=>\|>' },
        \ ']': {'pattern': '[[\]]', 'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0},
        \ ')': {'pattern': '[()]', 'left_margin': 0, 'right_margin': 0, 'stick_to_left': 0},
        \ 'f': {'pattern': ' \(\S\+(\)\@=', 'left_margin': 0, 'right_margin': 0 },
        \ 'd': {'pattern': ' \(\S\+\s*[;=]\)\@=', 'left_margin': 0, 'right_margin': 0},
        \ ';': {'pattern': ':', 'left_margin': 0, 'right_margin': 1, 'stick_to_left': 1},
        \ '/': {'pattern': '//\+\|/\*\|\*/', 'delimiter_align': 'l', 'ignore_groups': ['^\(.\(Comment\)\@!\)*$']},
        \ '=': {'pattern': '===\|<=>\|=\~[#?]\?\|=>\|[:+/*!%^=><&|.-?]*=[#?]\?\|[-=]>\|<[-=]', 'left_margin': 1, 'right_margin': 1, 'stick_to_left': 0}
        \}
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:vimEasyAlignOnSource'))
  endif

  if dein#tap('lexima.vim')
    function! s:leximaOnSource() abort
      silent! call remove(g:lexima#default_rules, 11, -1)
      for rule in g:lexima#default_rules + g:lexima#newline_rules
        call lexima#add_rule(rule)
      endfor | unlet rule

      function! s:disable_lexima_inside_regexp(char) abort
        call lexima#add_rule({'at': '\(...........\)\?/\S.*\%#.*\S/', 'char': a:char, 'input': a:char})
      endfunction

      " Fix pair completion
      for pair in split('() []')
        call lexima#add_rule({
          \ 'char': pair[0], 'at': '\(........\)\?\%#[^\s'.escape(pair[1], ']') .']', 'input': pair[0]
          \})
      endfor | unlet pair

      " Quotes
      for quote in split('" ''')
        call lexima#add_rule({'at': '\(.......\)\?'. quote .'\%#', 'char': quote, 'input': quote})
        call lexima#add_rule({'at': '\(...........\)\?\%#'. quote, 'char': quote, 'input': '<Right>'})
        call lexima#add_rule({'at': '\(.......\)\?'. quote .'\%#'. quote, 'char': '<BS>', 'delete': 1})
        call s:disable_lexima_inside_regexp(quote)
      endfor | unlet quote

      " { <Space> }
      call lexima#add_rule({
        \ 'filetype': ['javascript', 'yaml'],
        \ 'at': '\(.......\)\?{\%#}', 'char': '<Space>', 'input_after': '<Space>'
        \})

      " Twig / Blade
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
    nnoremap <silent> ! :<C-u>silent! call switch#Switch(g:switch_def_quotes, {'reverse': 1})<CR>
    nnoremap <silent> ` :<C-u>silent! call switch#Switch(g:switch_def_camelcase, {'reverse': 1})<CR>

    let g:switch_def_quotes = [{
      \ '''\(.\{-}\)''': '"\1"',
      \ '"\(.\{-}\)"':  '''\1''',
      \ '`\(.\{-}\)`':  '''\1'''
      \}]
    let g:switch_def_camelcase = [{
      \ '\<\(\l\)\(\l\+\(\u\l\+\)\+\)\>': '\=toupper(submatch(1)) . submatch(2)',
      \ '\<\(\u\l\+\)\(\u\l\+\)\+\>': "\\=tolower(substitute(submatch(0), '\\(\\l\\)\\(\\u\\)', '\\1_\\2', 'g'))",
      \ '\<\(\l\+\)\(_\l\+\)\+\>': '\U\0',
      \ '\<\(\u\+\)\(_\u\+\)\+\>': "\\=tolower(substitute(submatch(0), '_', '-', 'g'))",
      \ '\<\(\l\+\)\(-\l\+\)\+\>': "\\=substitute(submatch(0), '-\\(\\l\\)', '\\u\\1', 'g')"
      \}]

    " PHP
    AutocmdFT php let b:switch_custom_definitions = [
      \ ['prod', 'dev', 'test'],
      \ ['&&', '||'],
      \ ['and', 'or'],
      \ ['public', 'protected', 'private'],
      \ ['extends', 'implements'],
      \ ['string ', 'int ', 'array '],
      \ ['use', 'namespace'],
      \ ['var_dump', 'print_r'],
      \ ['include', 'require'],
      \ ['include_once', 'require_once'],
      \ ['$_GET', '$_POST', '$_REQUEST'],
      \ ['__DIR__', '__FILE__'],
      \ {
      \   '\([^=]\)===\([^=]\)': '\1==\2',
      \   '\([^=]\)==\([^=]\)': '\1===\2'
      \ },
      \ {
      \   '\[[''"]\(\k\+\)[''"]\]': '->\1',
      \   '\->\(\k\+\)': '[''\1'']'
      \ },
      \ {
      \   '\array(\(.\{-}\))': '[\1]',
      \   '\[\(.\{-}\)]': '\array(\1)'
      \ },
      \ {
      \   '^class\s\(\k\+\)': 'final class \1',
      \   '^final class\s\(\k\+\)': 'abstract class \1',
      \   '^abstract class\s\(\k\+\)': 'trait \1',
      \   '^trait\s\(\k\+\)': 'class \1'
      \ }
      \]

    " JavaScript
    AutocmdFT javascript let b:switch_custom_definitions = [
      \ ['get', 'set'],
      \ ['var', 'const', 'let'],
      \ ['<', '>'], ['==', '!=', '==='],
      \ ['left', 'right'], ['top', 'bottom'],
      \ ['getElementById', 'getElementByClassName'],
      \ {
      \   '\function\s*(\(.\{-}\))': '(\1) =>'
      \ }
      \]

    " HTML
    AutocmdFT html,twig let b:switch_custom_definitions = [
      \ ['h1', 'h2', 'h3'],
      \ ['png', 'jpg', 'gif'],
      \ ['id=', 'class=', 'style='],
      \ {
      \   '<div\(.\{-}\)>\(.\{-}\)</div>': '<span\1>\2</span>',
      \   '<span\(.\{-}\)>\(.\{-}\)</span>': '<div\1>\2</div>'
      \ },
      \ {
      \   '<ol\(.\{-}\)>\(.\{-}\)</ol>': '<ul\1>\2</ul>',
      \   '<ul\(.\{-}\)>\(.\{-}\)</ul>': '<ol\1>\2</ol>'
      \ }
      \]

    " CSS
    AutocmdFT css let b:switch_custom_definitions = [
      \ ['border-top', 'border-bottom'],
      \ ['border-left', 'border-right'],
      \ ['border-left-width', 'border-right-width'],
      \ ['border-top-width', 'border-bottom-width'],
      \ ['border-left-style', 'border-right-style'],
      \ ['border-top-style', 'border-bottom-style'],
      \ ['margin-left', 'margin-right'],
      \ ['margin-top', 'margin-bottom'],
      \ ['padding-left', 'padding-right'],
      \ ['padding-top', 'padding-bottom'],
      \ ['margin', 'padding'],
      \ ['height', 'width'],
      \ ['min-width', 'max-width'],
      \ ['min-height', 'max-height'],
      \ ['transition', 'animation'],
      \ ['absolute', 'relative', 'fixed'],
      \ ['inline', 'inline-block', 'block', 'flex'],
      \ ['overflow', 'overflow-x', 'overflow-y'],
      \ ['before', 'after'],
      \ ['none', 'block'],
      \ ['left', 'right'],
      \ ['top', 'bottom'],
      \ ['em', 'px', '%'],
      \ ['bold', 'normal'],
      \ ['hover', 'active']
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
    let s:color_codes_ft = split('css html twig')

    Autocmd BufNewFile,BufRead,BufEnter,WinEnter,BufWinEnter *
      \ execute index(s:color_codes_ft, &filetype) == -1
        \ ? 'call s:removeColorizerEvent()'
        \ : 'ColorHighlight'

    function! s:removeColorizerEvent() abort
      if !exists('#Colorizer') | return | endif
      augroup Colorizer
        autocmd!
      augroup END
      augroup! Colorizer
    endfunction
  endif

  if dein#tap('vimfiler.vim')
    " ;d: open vimfiler explrer
    nnoremap <silent> ;d :<C-u>VimFiler -split -invisible -create -no-quit<CR>
    " Tab: jump to vimfiler window
    nnoremap <silent> <Tab> :<C-u>call <SID>jumpToVimfiler()<CR>

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
      nmap <buffer> <expr> q winnr('$') == 1 ? "\<Plug>(vimfiler_hide)" : "\<Plug>(vimfiler_switch_to_other_window)"
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
        \ '^\%(\..*\|^.\|.git\|.hg\|bin\|var\|etc\|build\|vendor\|node_modules\|gulpfile.js\|package.json\)$'

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
    nmap ;q <Plug>(quickrun)
    nnoremap <expr> <silent> ;Q quickrun#is_running() ? quickrun#sweep_sessions() : "\<C-c>"

    AutocmdFT php
      \  nnoremap <silent> <buffer> ,w :<C-u>call <SID>quickrunType('csfixer')<CR>
      \| nnoremap <silent> <buffer> ,t :<C-u>call <SID>quickrunType('phpunit')<CR>

    AutocmdFT javascript,html,twig,css,json
      \ nnoremap <silent> <buffer> ,w :<C-u>call <SID>quickrunType('formatter')<CR>

    AutocmdFT javascript
      \ nnoremap <silent> <buffer> ,t :<C-u>call <SID>quickrunType('nodejs')<CR>
      \| nnoremap <silent> <buffer> ,W :<C-u>call <SID>quickrunType('lint')<CR>

    AutocmdFT xml
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
      let g:quickrun_config._ = {
        \ 'outputter': 'null',
        \ 'runner': 'vimproc',
        \ 'runner/vimproc/updatetime': 30
        \}

      " PHP
      let g:quickrun_config['php/csfixer'] = {
        \ 'command': 'php-cs-fixer', 'exec': '%c -q fix %a -- %s', 'outputter': 'reopen',
        \ 'args': '--rules=@PSR2'
        \}
      let g:quickrun_config['php/phpunit'] = {
        \ 'command': 'phpunit', 'exec': '%c %a', 'outputter': 'phpunit',
        \ 'args': printf('-c %s/preset/phpunit.xml.dist', $VIMFILES)
        \}

      " JavaScript
      let g:quickrun_config['javascript/nodejs'] = {
        \ 'command': 'node', 'exec': '%c %a %s', 'outputter': 'buffer',
        \ 'outputter/buffer/name': 'runner:nodejs',
        \ 'outputter/buffer/filetype': 'json',
        \ 'outputter/buffer/running_mark': '...'
        \}
      let g:quickrun_config['javascript/formatter'] = {
        \ 'command': 'esformatter', 'exec': '%c %a %s', 'outputter': 'rebuffer',
        \ 'args': printf('--config %s/preset/esformatter_js.json --no-color', $VIMFILES)
        \}
      let g:quickrun_config['javascript/lint'] = {
        \ 'command': 'eslint', 'exec': '%c %a %s', 'outputter': 'eslint',
        \ 'args': printf('-c %s/preset/.eslintrc --no-color -f compact', $VIMFILES)
        \}

      " CSS
      let g:quickrun_config['css/formatter'] = {
        \ 'command': 'postcss', 'exec': '%c %a %s', 'outputter': 'rebuffer',
        \ 'args': printf('--use postcss-sorting --config %s/preset/postcss_sort.js', $VIMFILES)
        \}

      " HTML
      let g:quickrun_config['html/formatter'] = {
        \ 'command': 'html-beautify', 'exec': '%c -f %s %a', 'outputter': 'rebuffer',
        \ 'args': '--indent-size 2 --unformatted script'
        \}
      " Twig
      let g:quickrun_config['twig/formatter'] = g:quickrun_config['html/formatter']

      " XML
      let g:quickrun_config['xml/formatter'] = {
        \ 'command': 'tidy', 'exec': '%c %a %s', 'outputter': 'rebuffer',
        \ 'args': printf('-config %s/preset/tidy_xml.config', $VIMFILES)
        \}

      " JSON
      let g:quickrun_config['json/formatter'] = {
        \ 'command': 'js-beautify', 'exec': '%c -f %s %a', 'outputter': 'rebuffer',
        \ 'args': '--indent-size 2'
        \}
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:quickrunOnSource'))
  endif

  if dein#tap('agit.vim')
    AutocmdFT agit setlocal cursorline
    AutocmdFT agit* let &l:statusline = ' '
    AutocmdFT agit* call s:agitMappings()

    function! s:agitMappings() abort
      nmap <buffer> u <PLug>(agit-reload)
      nmap <buffer> r <Plug>(agit-git-reset)
      nmap <buffer> R <Plug>(agit-git-rebase)
      nmap <buffer> E <Plug>(agit-print-commitmsg)
    endfunction

    Autocmd Syntax agit* call s:agitColors()
    function! s:agitColors() abort
      hi AgitRef          guifg=#2B2B2B guibg=#F6F7F7 gui=NONE
      hi agitRemote       guifg=#2B2B2B guibg=#F6F7F7 gui=bold
      hi AgitHead         guifg=#2B2B2B guibg=#F6F7F7 gui=bold
      hi AgitHeaderLabel  guifg=#2B2B2B guibg=#F6F7F7 gui=bold
      hi AgitAuthor       guifg=#2B2B2B guibg=#F6F7F7 gui=bold
      hi link AgitDiffAdd       DiffAdd
      hi link AgitDiffRemove    DiffDelete
      hi link AgitStatFile      AgitDiffHeader
      hi link AgitDate          Comment
      hi link agitTree          Comment
      hi link agitUntrackedFile Normal
    endfunction
  endif

  if dein#tap('vim-gita')
    AutocmdFT gita,gita*  call s:gitaFiletypes() | call s:gitaBaseMappings()
    AutocmdFT gita-{branch,status,commit} call s:gitaSpecialMappings()

    function! s:gitaFiletypes() abort
      let &l:statusline = ' ' | setlocal nonu nornu
      Autocmd InsertEnter <buffer> setlocal nocursorline
      Autocmd InsertLeave <buffer> setlocal cursorline
    endfunction

    function! s:gitaBaseMappings() abort
      nmap <silent> <buffer> q :<C-u>bdelete<CR>
      nmap <silent> <buffer> Q :<C-u>bdelete!<CR>
    endfunction

    function! s:gitaSpecialMappings() abort
      nmap <buffer> m <Plug>(gita-toggle)
      nmap <buffer> c <Plug>(gita-commit)
      nmap <buffer> C <Plug>(gita-commit-do)
      nmap <buffer> A <Plug>(gita-commit-amend)
      nmap <buffer> t <Plug>(gita-edit-tab)
      nmap <buffer> o <Plug>(gita-edit-preview)
      nmap <buffer> O <Plug>(gita-edit)
      nmap <buffer> r <Plug>(gita-status)
      nmap <buffer> R <Plug>(gita-redraw)
    endfunction

    Autocmd Syntax gita,gita* call s:gitaColors()
    function! s:gitaColors() abort
      hi GitaBranch   guifg=#2B2B2B guibg=#F6F7F7 gui=bold
      hi GitaSelected guifg=#2B2B2B guibg=#F6F7F7 gui=bold
      hi link GitaUntracked Normal
      hi link GitaKeyword   MatchParen
    endfunction
  endif

  if dein#tap('context_filetype.vim')
    function! s:addContext(filetype, rule) abort
      let context_ft_def = get(context_filetype#default_filetypes(), a:filetype, [])
      let g:context_filetype#filetypes[a:filetype] = add(context_ft_def, a:rule)
    endfunction

    " CSS
    let s:context_ft_css = {
      \ 'filetype': 'css',
      \ 'start':    '<script\%( [^>]*\)\?>',
      \ 'end':      '</style>'
      \}
    for filetype in split('html twig blade')
      call s:addContext(filetype, s:context_ft_css)
    endfor | unlet filetype
  endif

  if dein#tap('neocomplete.vim')
    imap <Tab> <Plug>(neocomplete)
    imap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<Plug>(neocomplete)"',
    imap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<C-x>\<C-o>"
    imap <expr> <C-j>   pumvisible() ? "\<C-n>" : "\<C-g>u<C-u>"
    imap <expr> <C-k>   pumvisible() ? "\<C-p>" : col('.') ==# col('$') ? "\<C-k>" : "\<C-o>D"

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
          \ : neocomplete#start_manual_complete()
      endif
      return a:key
    endfunction

    function! s:neocompleteOnSource() abort
      let g:neocomplete#enable_at_startup = 1
      let g:neocomplete#enable_smart_case = 1
      let g:neocomplete#enable_camel_case = 1
      let g:neocomplete#enable_auto_delimiter = 1
      let g:neocomplete#min_keyword_length = 2
      let g:neocomplete#auto_completion_start_length = 2
      let g:neocomplete#manual_completion_start_length = 2
      let g:neocomplete#data_directory = $CACHE.'/neocomplete'

      " Custom settings
      call neocomplete#custom#source('tag', 'rank', 60)
      call neocomplete#custom#source('omni', 'rank', 80)
      call neocomplete#custom#source('ultisnips', 'rank', 100)
      call neocomplete#custom#source('ultisnips', 'min_pattern_length', 1)

      " Sources
      let g:neocomplete#sources = {
        \ '_':          ['buffer', 'file/include'],
        \ 'rust':       ['omni', 'file/include', 'ultisnips'],
        \ 'javascript': ['omni', 'file/include', 'ultisnips', 'tag'],
        \ 'haskell':    ['omni', 'file/include', 'ultisnips', 'tag'],
        \ 'php':        ['omni', 'file/include', 'ultisnips', 'tag'],
        \ 'css':        ['omni', 'file/include', 'ultisnips'],
        \ 'html':       ['omni', 'file/include', 'ultisnips'],
        \ 'xml':        ['omni', 'file/include', 'ultisnips', 'buffer'],
        \ 'twig':       ['omni', 'file/include', 'ultisnips'],
        \ 'blade':      ['omni', 'file/include', 'ultisnips']
        \}

      " Completion patterns
      let g:neocomplete#sources#omni#input_patterns = {
        \ 'haskell':    '\h\w*\|\(import\|from\)\s',
        \ 'rust':       '[^.[:digit:] *\t]\%(\.\|\::\)\%(\h\w*\)\?',
        \ 'sql':        '\h\w*\|[^.[:digit:] *\t]\%(\.\)\%(\h\w*\)\?',
        \ 'javascript': '\h\w*\|\h\w*\.\%(\h\w*\)\?\|[^. \t]\.\%(\h\w*\)\?\|\(import\|from\)\s',
        \ 'php':        '[^. \t]->\%(\h\w*\)\?\|\h\w*::\%(\h\w*\)\?\|\(new\|use\|extends\|implements\|instanceof\)\%(\s\|\s\\\)'
        \}
      call neocomplete#util#set_default_dictionary('g:neocomplete#sources#omni#input_patterns',
        \ 'html,twig,xml', '<\|\s[[:alnum:]-]*')
      call neocomplete#util#set_default_dictionary('g:neocomplete#sources#omni#input_patterns',
        \ 'css,scss,sass,sss', '\w\+\|\w\+[):;]\?\s\+\w*\|[@!]')

      " Dictionary
      let g:neocomplete#sources#dictionary#dictionaries = {
        \ 'default' : '',
        \ 'php' : $VIMFILES.'/dict/phpunit'
        \}
      Autocmd BufNewFile,BufRead *Test.php
        \ let b:neocomplete_sources = ['omni', 'file/include', 'ultisnips', 'tag', 'dictionary']
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:neocompleteOnSource'))
  endif

  if dein#tap('ultisnips')
    imap ` <Plug>(ultisnips)
    xmap ` <Plug>(ultisnipsVisual)
    snoremap <C-c> <Esc>

    inoremap <silent> <Plug>(ultisnips) <C-r>=<SID>ultiComplete("\`")<CR>
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
      let g:UltiSnipsSnippetsDir = $VIMFILES.'/dev/dotvim/ultisnips'

      AutocmdFT twig  call UltiSnips#AddFiletypes('twig.html')
      AutocmdFT blade call UltiSnips#AddFiletypes('blade.html')
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

    function! s:easymotionColors() abort
      hi EasyMotionTarget       guifg=#2B2B2B guibg=#F6F7F7 gui=bold
      hi EasyMotionTarget2First guifg=#FF0000 guibg=#F6F7F7 gui=bold
      hi link EasyMotionShade         Comment
      hi link EasyMotionMoveHL        Search
      hi link EasyMotionIncCursor     Cursor
      hi link EasyMotionTarget2Second EasyMotionTarget
      Autocmd ColorScheme * call s:easymotionColors()
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:easymotionOnSource'))
    call dein#set_hook(g:dein#name, 'hook_post_source', function('s:easymotionColors'))
  endif

  if dein#tap('unite.vim')
    " ;b: open buffers
    nnoremap <silent> ;b :<C-u>Unite buffer -toggle<CR>
    " ;f: open files
    nnoremap <silent> ;f
      \ :<C-u>UniteWithCurrentDir file_rec/async file/new directory/new -start-insert<CR>
    " ;H: open tab pages
    nnoremap <silent> ;H
      \ :<C-u>Unite tab -buffer-name=tabs -select=`tabpagenr()-1` -toggle<CR>
    " ;h: open windows
    nnoremap <silent> ;h :<C-u>Unite window:all:no-current -toggle<CR>

    " ;s: search
    nnoremap <silent> ;s
      \ :<C-u>Unite line:all -buffer-name=search%`bufnr('%')` -no-wipe -no-split -start-insert<CR>

    " ;r: resume search buffer
    nnoremap <silent> ;r
      \ :<C-u>UniteResume search%`bufnr('%')` -no-start-insert -force-redraw<CR>

    " Unite tuning
    AutocmdFT unite* setlocal nolist
    AutocmdFT unite* Autocmd InsertEnter,InsertLeave <buffer>
      \ setlocal nonu nornu nolist colorcolumn=

    AutocmdFT unite* call s:uniteMappings()
    function! s:uniteMappings() abort
      let b:unite = unite#get_current_unite()

      " Normal mode
      nmap <buffer> <BS> <Nop>
      nmap <buffer> e <Nop>
      nmap <buffer> <C-k> <C-u>
      nmap <buffer> R     <Plug>(unite_redraw)
      nmap <buffer> <Tab> <Plug>(unite_insert_head)
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
        \ unite#mappings#get_current_sorters() == [] ? ['sorter_ftime', 'sorter_reverse'] : []) . "\<Plug>(unite_redraw)"

      " Insert mode
      imap <buffer> <C-e> <C-o>A
      imap <buffer> <C-a> <Plug>(unite_move_head)
      imap <buffer> <C-j> <Plug>(unite_move_left)
      imap <buffer> <C-l> <Plug>(unite_move_right)
      imap <buffer> <Tab> <Plug>(unite_insert_leave)
      imap <buffer> <C-j> <Plug>(unite_select_next_line)
      imap <buffer> <C-k> <Plug>(unite_select_previous_line)
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

      let search_tool =
        \ executable('pt') ? 'pt' :
        \ executable('ag') ? 'ag' : ''
      if !empty(search_tool)
        let g:unite_source_grep_command = search_tool
        let g:unite_source_grep_recursive_opt = ''
        let g:unite_source_grep_encoding = 'utf-8'
        let g:unite_source_grep_default_opts = '--nogroup --nocolor --follow --smart-case'
        let g:unite_source_rec_async_command = [
          \ search_tool, &smartcase ? '-S' : '', '--nocolor', '--nogroup', '--hidden', '--follow', '-l', '.'
          \]
      endif

      " Default profile
      let unite_default = {
        \ 'winheight': 20,
        \ 'direction': 'botright',
        \ 'prompt_direction': 'bellow',
        \ 'cursor_line_time': '0.0',
        \ 'short_source_names': 1,
        \ 'hide_source_names': 1,
        \ 'hide_icon': 0,
        \ 'marked_icon': '+',
        \ 'prompt': '>',
        \ 'wipe': 1
        \}
      " Grep profile
      let unite_grep = {
        \ 'winheight': 20
        \}
      " Quickfix profile
      let unite_quickfix = {
        \ 'winheight': 16,
        \ 'no_quit': 1,
        \ 'keep_focus': 1
        \}

      " Custom profiles
      call unite#custom#profile('default', 'context', unite_default)
      call unite#custom#profile('grep', 'context', unite_grep)
      call unite#custom#profile('quickfix', 'context', unite_quickfix)
      " Custom filters
      call unite#custom#source('file_rec/async', 'max_candidates', 40)
      call unite#custom#source('file_rec/async', 'matchers', ['converter_relative_word', 'matcher_fuzzy'])
    endfunction

    function! s:uniteColors() abort
      hi link uniteStatusHead             StatusLine
      hi link uniteStatusNormal           StatusLine
      hi link uniteStatusMessage          StatusLine
      hi link uniteStatusSourceNames      StatusLine
      hi link uniteStatusSourceCandidates User1
      hi link uniteStatusLineNR           User2
      Autocmd Syntax unite call s:uniteColors()
    endfunction

    call dein#set_hook(g:dein#name, 'hook_source', function('s:uniteOnSource'))
    call dein#set_hook(g:dein#name, 'hook_post_source', function('s:uniteColors'))
  endif

  if dein#tap('neomru.vim')
    " ;w: open recently-opened files in project
    nnoremap <silent> ;w
      \ :<C-u>call <SID>openMRU(['matcher_fuzzy', 'matcher_hide_current_file', 'matcher_project_files'])<CR>
    " ;W: open recently-opened files
    nnoremap <silent> ;W
      \ :<C-u>call <SID>openMRU(['matcher_fuzzy', 'matcher_hide_current_file'])<CR>

    function! s:openMRU(matchers) abort
      call unite#custom#source('neomru/file', 'matchers', a:matchers)
      Unite neomru/file -toggle
    endfunction
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
  " Indent
  AutocmdFT php setlocal nowrap textwidth=120 | Indent 4
  " Syntax
  AutocmdFT php let [g:php_sql_query, g:php_highlight_html] = [1, 1]

  if dein#tap('phpunit.vim')
    AutocmdFT php call s:phpunitMappings()

    function! s:phpunitMappings() abort
      nnoremap <silent> <buffer> ,T :<C-u>PHPUnitRunAll<CR>
      nnoremap <silent> <buffer> ,t :<C-u>PHPUnitRunCurrentFile<CR>
      " nnoremap <silent> <buffer> ,f :<C-u>PHPUnitRunFilter<CR>

      for char in split('ta tf ts')
        execute printf('silent! iunmap %s', char)
      endfor | unlet char
    endfunction

    function! s:phpunitColors() abort
      hi! link PHPUnitOK         Todo
      hi! link PHPUnitFail       WarningMsg
      hi! link PHPUnitAssertFail Error
      Autocmd Syntax phpunit call s:phpunitColors()
    endfunction

    call dein#set_hook(g:dein#name, 'hook_post_source', function('s:phpunitColors'))
  endif

" JavaScript
  Autocmd BufNewFile,BufRead *.{jsx,es6} setlocal filetype=javascript
  " Indent
  AutocmdFT javascript setlocal nowrap textwidth=120 | Indent 2

" HTML
  " Indent
  AutocmdFT html setlocal textwidth=120 | Indent 2

" Twig
  Autocmd BufNewFile,BufRead *.{twig,*.twig} setlocal filetype=twig
  " Indent
  AutocmdFT twig setlocal textwidth=120 | Indent 2
  " Syntax
  AutocmdFT twig setlocal commentstring={#<!--%s-->#}

  if dein#tap('twig.vim')
    function! s:twigColors() abort
      echo 333
      hi twigVariable  guifg=#2B2B2B gui=bold
      hi twigStatement guifg=#008080 gui=NONE
      hi twigOperator  guifg=#999999 gui=NONE
      hi link twigBlockName twigVariable
      hi link twigVarDelim  twigOperator
      hi link twigTagDelim  twigOperator
    endfunction

    Autocmd Syntax twig call s:twigColors()
  endif

" Blade
  Autocmd BufNewFile,BufRead *.blade.php setlocal filetype=blade
  " Indent
  AutocmdFT blade setlocal textwidth=120 | Indent 2
  " Syntax
  AutocmdFT blade setlocal commentstring={{--%s--}}

  if dein#tap('vim-blade')
    function! s:bladeColors() abort
      hi bladeEcho          guifg=#2B2B2B gui=bold
      hi bladeKeyword       guifg=#008080 gui=NONE
      hi bladePhpParenBlock guifg=#999999 gui=NONE
      hi link bladeDelimiter phpParent
      " Reset SQL syntax
      hi link sqlStatement phpString
      hi link sqlKeyword   phpString
      Autocmd Syntax blade call s:bladeColors()
    endfunction

    call dein#set_hook(g:dein#name, 'hook_post_source', function('s:bladeColors'))
  endif

" CSS
  AutocmdFT css setlocal nonumber norelativenumber
  " Indent
  AutocmdFT css setlocal nowrap | Indent 2
  " Syntax
  AutocmdFT css setlocal iskeyword+=-,%,:

  if dein#tap('css.vim')
    function! s:cssColors() abort
      hi link cssError Normal
      hi link cssBraceError Normal
      hi link cssDeprecated Normal
      Autocmd Syntax css call s:cssColors()
    endfunction

    call dein#set_hook(g:dein#name, 'hook_post_source', function('s:cssColors'))
  endif

" Sugar CSS
  Autocmd BufNewFile,BufRead *.{scss,sss}
    \ setlocal filetype=css syntax=sass commentstring=//%s
  " Syntax
  Autocmd Syntax sass
    \ hi sassClass guifg=#2B2B2B guibg=#F6F7F7 gui=bold
  " Mappings
  AutocmdFT css
    \ nnoremap <silent> <buffer> <C-Enter> :<C-u>TrimWhiteSpace<CR>:write!<CR>

" JSON
  Autocmd BufNewFile,BufRead .{babelrc,eslintrc} setlocal filetype=json
  " Indent
  AutocmdFT json setlocal nonu nornu | Indent 2
    \| Autocmd BufNewFile,BufRead <buffer> setlocal formatoptions+=2l

  if dein#tap('vim-json')
    AutocmdFT json
      \ nnoremap <silent> <buffer> ,c :<C-u>let &l:conceallevel = (&l:conceallevel == 0 ? 2 : 0)<CR>
        \:echo printf(' Conceal mode: %3S (local)', (&l:conceallevel == 0 ? 'Off' : 'On'))<CR>

    Autocmd Syntax json
      \ syntax match jsonComment "//.\{-}$" | hi! link jsonComment Comment
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
      winsize 190 34 | winpos 492 326
    endif
    set guioptions=ac
    set guicursor=a:blinkon0  " turn off blinking the cursor
    set linespace=3           " extra spaces between rows

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
    silent! colorscheme topos
    " Reload the colorscheme whenever we write the file
    execute 'Autocmd BufWritePost '. g:colors_name '.vim colorscheme '. g:colors_name
  endif

  set shortmess=aoOtTIcF
  set number relativenumber    " show the line number
  set nocursorline             " highlight the current line
  set hidden                   " allows the closing of buffers without saving
  set switchbuf=useopen,split  " orders to open the buffer
  set showtabline=1            " always show the tab pages
  set noequalalways            " resize windows as little as possible
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
  Autocmd InsertEnter * execute 'setl listchars+=trail:'. s:trailchar
  Autocmd InsertLeave * execute 'setl listchars-=trail:'. s:trailchar

  " Title-line
  set title titlestring=%t%(\ %M%)%(\ (%{expand(\"%:~:.:h\")})%)%(\ %a%)

  " Command-line
  set cmdheight=1
  set noshowmode   " don't show the mode ('-- INSERT --') at the bottom
  set wildmenu wildmode=longest,full

  " Status-line
  set laststatus=2
  " Format the statusline
  let &statusline =
    \  "%3* %L %*"
    \. "%l%3*:%*%v "
    \. "%-0.60t "
    \. "%3*%(%{IfFit(70) ? expand('%:~:.:h') : ''}\ %)%*"
    \. "%2*%(%{exists('*BufModified') ? BufModified() : ''}\ %)%*"
    \. "%="
    \. "%(%{IfFit(100) && exists('*FileSize') ? FileSize() : ''}\ %)"
    \. "%2*%(%{IfFit(100) && &paste ? '[P]' : ''}\ %)%*"
    \. "%2*%(%{IfFit(100) ? &iminsert ? 'RU' : 'EN' : ''}\ %)%*"
    \. "%(%{IfFit(90) ? !empty(&fileencoding) ? &fileencoding : &encoding : ''}\ %)"
    \. "%2*%(%Y\ %)%*"

  " Status-line functions
  function! IfFit(width) abort
    return winwidth(0) > a:width
  endfunction

  function! BufModified() abort
    return &modified ? '+' : &modifiable ? '' : '-'
  endfunction

  function! FileSize() abort
    let size = &encoding ==# &fileencoding || &fileencoding ==# ''
      \ ? line2byte(line('$') + 1) - 1
      \ : getfsize(expand('%:p'))
    return size <= 0 ? '' :
      \ size < 1024 ? size.'B' : (size / 1024).'K'
  endfunction

" Edit
"---------------------------------------------------------------------------
  set report=0           " reporting number of lines changes
  set lazyredraw         " don't redraw while executing macros
  set nostartofline      " avoid moving cursor to BOL when jumping around
  set virtualedit=all    " allows the cursor position past true end of line
  " set clipboard=unnamed  " use * register for copy-paste

  " Keymapping timeout (mapping / keycode)
  set notimeout ttimeoutlen=100

  " Indent
  set cindent          " smart indenting for c-like code
  set autoindent       " indent at the same level of the previous line
  set shiftround       " indent multiple of shiftwidth
  set expandtab        " spaces instead of tabs
  set tabstop=2        " number of spaces per tab for display
  set shiftwidth=2     " number of spaces per tab in insert mode
  set softtabstop=2    " number of spaces when indenting
  set nojoinspaces     " prevents inserting two spaces after punctuation on a join (J)
  " Backspacing setting
  set backspace=indent,eol,start

  " Search
  set hlsearch         " highlight search results
  set incsearch        " find as you type search
  set ignorecase
  set smartcase
  set magic            " change the way backslashes are used in search patterns
  set gdefault         " flag 'g' by default for replacing

" Shortcuts
"---------------------------------------------------------------------------
  " Insert the current file
  iab <silent> ##f <C-r>=expand('%:t:r')<CR>
  ca ##f <C-r>=expand('%:t:r')<CR>
  " Insert the current file path
  ia <silent> ##p <C-r>=expand('%:p')<CR>
  ca ##p <C-r>=expand('%:p')<CR>
  " Insert the current file directory
  ia <silent> ##d <C-r>=expand('%:p:h').'\'<CR>
  ca ##d <C-r>=expand('%:p:h').'\'<CR>
  " Inset the current timestamp
  ia <silent> ##t <C-r>=strftime('%Y-%m-%d')<CR>
  ca ##t <C-r>=strftime('%Y-%m-%d')<CR>
  " Inset the current Unix time
  ia <silent> ##l <C-r>=localtime()<CR>
  ca ##l <C-r>=localtime()<CR>
  " Shebang
  ia <silent> <expr> ##! '#!/usr/bin/env' . (empty(&filetype) ? '' : ' '.&filetype)

" Normal mode
"---------------------------------------------------------------------------
  " Buffers
  "-----------------------------------------------------------------------
  " Space + A: next buffer
  nnoremap <silent> <Space>A :<C-u>bnext<CR>
  " Space + E: previous buffer
  nnoremap <silent> <Space>E :<C-u>bprev<CR>
  " Space + d: delete buffer
  nnoremap <silent> <Space>d :<C-u>bdelete<CR>
  " Space + D: force delete buffer
  nnoremap <silent> <Space>D :<C-u>bdelete!<CR>
  " Space + i: jump to alternate buffer
  nnoremap <silent> <Space>i <C-^>

  " Files
  "-----------------------------------------------------------------------
  " Ctrl-Enter: save file
  nnoremap <silent> <C-Enter> :<C-u>write!<CR>
  " Shift-Enter: force save file
  nnoremap <silent> <S-Enter> :<C-u>update!<CR>
  " ;e: reopen file
  nnoremap <silent> ;e :<C-u>edit<CR>
  " ;E: force reopen file
  nnoremap <silent> ;E :<C-u>edit!<CR>

  " Tabs
  "-----------------------------------------------------------------------
  " Space + 1-9: jumps to a tab number
  for n in range(1, 9)
    execute printf('nnoremap <silent> <nowait> <Space>%d %dgt', n, n)
  endfor | unlet n
  " Space + a: previous tab
  nnoremap <silent> <Space>a :<C-u>tabprev<CR>
  " Space + e: next tab
  nnoremap <silent> <Space>e :<C-u>tabnext<CR>
  " Space + o: tab only
  nnoremap <silent> <Space>o :<C-u>tabonly<CR>
  " Space + t: tab new
  nnoremap <silent> <Space>t :<C-u>tabnew<CR>:normal! <C-o><CR>
  " Space + T: tab new and move
  nnoremap <silent> <Space>T :<C-u>tabnew<CR>:tabmove<CR>:normal! <C-o><CR>

  " Windows
  "-----------------------------------------------------------------------
  for char in split('h j k l')
    " Space + [hjkl]: jump to a window
    execute printf('nnoremap <silent> <Space>%s :<C-u>wincmd %s<CR>', char, char)
    " Space + [HJKL]: move the current window
    execute printf('nnoremap <silent> <Space>%s :<C-u>wincmd %s<CR>', toupper(char), toupper(char))
  endfor | unlet char
  " Space + w: next window
  nnoremap <silent> <Space>w :<C-u>wincmd w<CR>
  " Space + W: previous window
  nnoremap <silent> <Space>W :<C-u>wincmd W<CR>
  " Space + I: previous (last accessed) window
  nnoremap <silent> <Space>I :<C-u>wincmd p<CR>
  " Space + v: split window horizontaly
  nnoremap <silent> <expr> <Space>v ':<C-u>'. (v:count ? v:count : '') .'split<CR>'
  " Space + V: split window verticaly
  nnoremap <silent> <expr> <Space>V ':<C-u>vertical '. (v:count ? v:count : '') .'split<CR>'
  " Space + q: smart close window -> tab -> buffer
  nnoremap <silent> <expr> <Space>q winnr('$') == 1
    \ ? printf(':<C-u>%s<CR>', (tabpagenr('$') == 1 ? 'bdelete!' : 'tabclose!'))
    \ : ':<C-u>close<CR>'
  " Space + Q: force smart close window -> tab -> buffer
  nnoremap <silent> <expr> <Space>Q winnr('$') == 1
    \ ? printf(':<C-u>%s<CR>', (tabpagenr('$') == 1 ? 'bdelete!' : 'tabclose!'))
    \ : ':<C-u>close!<CR>'

  " Special
  "-----------------------------------------------------------------------
  " jk: don't skip wrap lines
  nnoremap <expr> j v:count ? 'gj' : 'j'
  nnoremap <expr> k v:count ? 'gk' : 'k'
  " Alt-[jkhl]: move selected lines
  nnoremap <silent> <A-j> :<C-u>move+1<CR>
  nnoremap <silent> <A-k> :<C-u>move-2<CR>
  nnoremap <A-h> <<<Esc>
  nnoremap <A-l> >>><Esc>
  " Ctrl-[jk]: scroll up/down 1/3 page
  nnoremap <expr> <C-j> v:count ? "\<C-d>zz" : winheight('.') / (3 + 1) . "\<C-d>zz"
  nnoremap <expr> <C-k> v:count ? "\<C-u>zz" : winheight('.') / (3 + 1) . "\<C-u>zz"
  " Q: auto indent text
  nnoremap Q ==
  " Ctrl-d: duplicate line
  nnoremap <expr> <C-d> 'yyp'. col('.') .'l'
  " Ctrl-c: clear highlight after search
  nnoremap <silent> <C-c> :<C-u>let @/ = ""<CR>
  " [N]+Enter: jump to a line number / mark
  nnoremap <silent> <expr> <Enter> v:count ?
    \ ':<C-u>call cursor(v:count, 0)<CR>zz' : "\'"
  nnoremap <silent> <expr> n v:count ?
    \ ":\<C-u>for i in range(1, v:count1) \| call append(line('.'), '') \| endfor\<CR>" : 'i<Space><Esc>'
  nnoremap <silent> <expr> N v:count ?
    \ ":\<C-u>for i in range(1, v:count1) \| call append(line('.')-1, '') \| endfor\<CR>" : 'i<Space><Esc>`^'
  " ,ev: open .vimrc in a new tab
  nnoremap <silent> ,ev :<C-u>tabnew $MYVIMRC<CR>
  " [dDcC]: don't update register
  nnoremap d "_d
  nnoremap D "_D
  nnoremap c "_c
  nnoremap C "_C
  " nnoremap x "_x
  " nnoremap X "_dd

  " Text objects
  "-----------------------------------------------------------------------
  " vi
  nmap " <Esc>vi"
  for char in split(''' " ` ( [ { <')
    execute printf('nmap ;%s <Esc>vi%s', char, char)
  endfor | unlet char
  " va
  nmap ' <Esc>vi'
  for char in split(') ] } >')
    execute printf('nmap ;%s <Esc>va%s', char, char)
  endfor | unlet char

  " Unbinds
  "-----------------------------------------------------------------------
  for char in split('<F1> ZZ ZQ')
    execute printf('map %s <Nop>', char)
  endfor | unlet char

" Insert mode
"---------------------------------------------------------------------------
  " Alt-[jkhl]: standart move
  inoremap <A-j> <C-o>gj
  inoremap <A-h> <C-o>h
  inoremap <A-k> <C-o>gk
  inoremap <A-l> <C-o>l
  " Ctrl-a: jump to head
  inoremap <C-a> <C-o>I
  " Ctrl-e: jump to end
  inoremap <C-e> <C-o>A
  " Ctrl-d: delete next char
  inoremap <C-d> <Del>
  " Ctrl-Enter: break line below
  inoremap <C-CR> <Esc>O
  " Shift-Enter: break line above
  inoremap <S-CR> <C-m>
  " Ctrl-u: undo
  inoremap <C-u> <C-o>u
  " Ctrl-[pv]: paste
  imap <C-p> <S-Insert>
  imap <C-v> <S-Insert>
  " Ctrl-s: force save file
  inoremap <silent> <C-s> <Esc> :write!<CR>i
  " Ctrl-c: fast Esc
  inoremap <C-c> <Esc>`^
  " Ctrl-l: fast Esc
  inoremap <C-l> <Esc>`^
  " [jj|qq]: smart fast Esc
  inoremap <expr> j getline('.')[getcurpos()[4]-2] ==# 'j' ? "\<BS>\<Esc>`^" : "\j"
  inoremap <expr> q getline('.')[getcurpos()[4]-2] ==# 'q' ? "\<BS>\<Esc>`^" : "\q"

  " Unbinds
  inoremap <C-j> <Nop>
  inoremap <C-k> <Nop>

" Visual mode
"---------------------------------------------------------------------------
  " jk: don't skip wrap lines
  xnoremap <expr> j v:count && mode() ==# 'V' ? 'gj' : 'j'
  xnoremap <expr> k v:count && mode() ==# 'V' ? 'gk' : 'k'
  " Alt-[jkhl]: move selected lines
  xnoremap <silent> <A-j> :move'>+1<CR>gv
  xnoremap <silent> <A-k> :move-2<CR>gv
  xnoremap <A-h> <'[V']
  xnoremap <A-l> >'[V']
  " Ctrl-[jk]: scroll up/down
  xnoremap <C-j> <C-d>
  xnoremap <C-k> <C-u>
  " Ctrl-d: duplicate line
  xnoremap <silent> <C-d> :t'><CR>
  " Q: auto indent text
  xnoremap Q ==<Esc>
  " L: move to end of line
  xnoremap L $h
  " [#*]: make # and * work in visual mode too
  xnoremap # y?<C-r>*<CR>
  xnoremap * y/<C-r>*<CR>
  " [yY]: keep cursor position when yanking
  xnoremap <silent> <expr> y 'ygv'. mode()
  xnoremap <silent> <expr> Y 'Ygv'. mode()
  " p: paste not replace the default register
  xnoremap p "_dP
  " [dDcC]: delete to black hole register
  xnoremap d "_d
  xnoremap D "_D
  xnoremap c "_c
  xnoremap C "_C
  " xnoremap x "_x
  " xnoremap X "_X

  " Space: fast Esc
  snoremap <Space> <Esc>

" Command mode
"---------------------------------------------------------------------------
  " Ctrl-h: previous char
  cnoremap <C-h> <Left>
  " Ctrl-l: next char
  cnoremap <C-l> <Right>
  " Ctrl-h: previous word
  cnoremap <A-h> <S-left>
  " Ctrl-h: next word
  cnoremap <A-l> <S-right>
  " Ctrl-j: previous history
  cnoremap <C-j> <Down>
  " Ctrl-k: next history
  cnoremap <C-k> <Up>
  " Ctrl-d: delete char
  cnoremap <C-d> <Del>
  " Ctrl-a: jump to head
  cnoremap <C-a> <Home>
  " Ctrl-e: jump to end
  cnoremap <C-e> <End>
  " Ctrl-v: open the command-line window
  cnoremap <C-v> <C-f>a

  " Special
  "-----------------------------------------------------------------------
  " `: old fast Esc
  cnoremap <C-c> <C-c>
  " jj: smart fast Esc
  cnoremap <expr> j getcmdline()[getcmdpos()-2] ==# 'j' ? "\<C-c>" : 'j'
  " qq: smart fast Esc
  cnoremap <expr> q getcmdline()[getcmdpos()-2] ==# 'q' ? "\<C-c>" : 'q'
