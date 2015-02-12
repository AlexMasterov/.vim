" .vimrc / 2015 Feb
" Author: Alex Masterov <alex.masterow@gmail.com>
" Source: https://github.com/AlexMasterov/dotvim

" My vimfiles
"---------------------------------------------------------------------------
    let $VIMFILES = $VIM.'/vimfiles'
    let $VIMCACHE = $VIMFILES.'/cache'
    " Basic remapping
    let g:mapleader = ',' | nmap ; :
    " Ignore pattern
    let g:ignore_ext =
    \   'hq,git,svn'
    \.  ',png,jpg,jpeg,gif,ico,bmp'
    \.  ',zip,rar,tar,tar.bz,tar.bz2'
    \.  ',o,a,so,obj.pyc,bin,exe,lib,dll'
    \.  ',lock,bak,tmp,dist,doc,docx,md'
    let g:ignore_dir = ''

" Environment
"---------------------------------------------------------------------------
    if &compatible
        set nocompatible  " be improved
    endif
    set noexrc            " avoid reading local (g)vimrc, exrc
    set modelines=0       " prevents security exploits

    " Initialize autogroup in MyVimrc
    augroup MyVimrc| exe 'autocmd!' |augroup END

    " Echo startup time on start
    if has('vim_starting') && has('reltime')
        " Shell: vim --startuptime filename -q; vim filename
        " vim --cmd 'profile start profile.txt' --cmd 'profile file $HOME/.vimrc' +q && vim profile.txt
        let s:startuptime = reltime()
        au MyVimrc VimEnter * let s:startuptime = reltime(s:startuptime) | redraw
                    \| echomsg ' startuptime:'. reltimestr(s:startuptime)
    endif

" Functions
"---------------------------------------------------------------------------
    function! WINDOWS() abort
        return has('win32') || has('win64')
    endfunction

    function! MakeDir(dir, ...) abort
        let dir = expand(a:dir)
        if !isdirectory(a:dir) && (a:0 ||
                \ input(printf('"%s" does not exist. Create? [y/n]', dir)) =~? '^y\%[es]$')
            silent! call mkdir(iconv(dir, &encoding, &termencoding), 'p')
        endif
    endfunction

" Commands
"---------------------------------------------------------------------------
    " Vimrc augroup sugar
    command! -nargs=* Autocmd   au MyVimrc <args>
    command! -nargs=* AutocmdFT au MyVimrc FileType <args>
    command! -nargs=* ImapBufExpr imap <buffer> <expr> <args>
    command! -nargs=* Mkdir call MakeDir(<f-args>)
    " Indent
    command! -bar -nargs=* Indent
        \ exe 'setl tabstop='.<q-args> 'softtabstop='.<q-args> 'shiftwidth='.<q-args>
    " Font size
    command! -nargs=* FontSize
        \ let &guifont = substitute(&guifont, '\d\+', '\=submatch(0)+<args>', 'g')
    " Reload vimrc
    command! -bar ReloadVimrc
        \ if exists(':NeoBundleClearCache')| NeoBundleClearCache |endif | source $MYVIMRC | redraw
    " Strip trailing whitespace at the end of non-blank lines
    command! -bar FixWhitespace if !&bin| silent! :%s/\s\+$//ge |endif

" Events
"---------------------------------------------------------------------------
    " Reload vimrc
    Autocmd BufWritePost,FileWritePost $MYVIMRC ReloadVimrc
    " Reload vim script
    Autocmd BufWritePost,FileWritePost *.vim source <afile>
    " Resize splits then the window is resized
    Autocmd VimResized * wincmd =
    " Check timestamp more for 'autoread'
    Autocmd CursorHold <buffer> if &autoread| checktime |endif
    " Leave Insert mode and save when Vim lost focus
    Autocmd FocusLost * call feedkeys("\<Esc>") | silent! wall
    " Disable paste mode when leaving Insert mode
    Autocmd InsertLeave * if &paste| set nopaste |endif
    " Toggle settings between modes
    Autocmd InsertEnter * setl nu  nolist colorcolumn=80
    Autocmd InsertLeave * setl rnu list   colorcolumn&
    " Only show the cursorline in the current window
    Autocmd WinEnter,CursorHold,CursorHoldI   * setl cursorline
    Autocmd WinLeave,CursorMoved,CursorMovedI * if &cursorline| setl nocursorline |endif
    " Don't auto insert a comment when using O/o for a newline (see also :help fo-table)
    Autocmd BufEnter,WinEnter * set formatoptions-=ro
    " Automake directory
    Autocmd BufWritePre * call MakeDir('<afile>:p:h', v:cmdbang)
    " Converts all remaining tabs to spaces on save
    Autocmd BufReadPost,BufWrite * if &modifiable| FixWhitespace | retab |endif
    " Restore original functionality of keys inside quickfix
    Autocmd BufEnter,WinEnter quickfix nnoremap <buffer> <CR> <CR>

" Encoding
"---------------------------------------------------------------------------
    set encoding=utf-8
    scriptencoding utf-8

    if WINDOWS() && has('multi_byte')
        setglobal fileencodings=utf-8,cp1251
        set termencoding=cp850  " cmd.exe uses cp850
    else
        set termencoding=       " same as 'encoding'
    endif

    " Default fileformat
    set fileformat=unix
    set fileformats=unix,dos,mac

    " Open in UTF-8
    command! -bar -bang -nargs=? -complete=file Utf8 edit<bang> ++enc=utf-8 <args>
    " Open in CP1251
    command! -bar -bang -nargs=? -complete=file Cp1251 edit<bang> ++enc=cp1251 <args>

" Misc
"---------------------------------------------------------------------------
    if has('vim_starting')
        set viminfo+=n$VIMFILES/viminfo
        " Cache
        Mkdir $VIMCACHE 1
        set noswapfile
        " Undo
        Mkdir $VIMFILES/undo 1
        set undofile
        set undolevels=500 undoreload=1000
        set undodir=$VIMFILES/undo
        " View
        set viewdir=$VIMFILES/views
        set viewoptions=cursor,folds,slash,unix
    endif

    " Russian keyboard
    set iskeyword=@,48-57,_,192-255
    set keymap=russian-jcukenwin
    if has('multi_byte_ime')
        set iminsert=0 imsearch=0
    endif

    " Regexp engine (0=auto, 1=old, 2=NFA)
    if exists('&regexpengine')
        set regexpengine=2
    endif

    " Search tool
    let s:search_tool = executable('pt') ? 'pt' : executable('ag') ? 'ag' : ''
    let &grepprg = s:search_tool
    \.  ' '. join(map(split(g:ignore_ext, ','), '"\--ignore *.".v:val.""'), ' ')
    \.  ' '. join(map(split(g:ignore_dir, ','), '"\--ignore ".v:val.""'), ' ')
    \.  (&smartcase ? ' -S' : ''). ' --follow --nogroup --nocolor'

" Plugins
"---------------------------------------------------------------------------
    " Avoid loading same default plugins
    let g:loaded_gzip = 1
    let g:loaded_zipPlugin = 1
    let g:loaded_tarPlugin = 1
    let g:loaded_rrhelper = 1
    let g:loaded_matchparen = 1
    let g:loaded_netrwPlugin = 1
    let g:loaded_2html_plugin = 1
    let g:loaded_vimballPlugin = 1
    let g:loaded_getscriptPlugin = 1
    let g:loaded_spellfile_plugin = 1
    let g:did_install_default_menus = 1

    " Install NeoBundle
    if has('vim_starting')
        let s:neobundle_path = $VIMFILES.'/bundle/neobundle.vim'
        let s:neobundle_uri  = 'https://github.com/Shougo/neobundle.vim'
        if !isdirectory(s:neobundle_path)
            Mkdir $VIMFILES/bundle 1
            if executable('git')
                call system(printf('git clone --depth 1 %s %s',
                            \ s:neobundle_uri, s:neobundle_path))
            else
                echom "Can\'t download NeoBundle: Git not found."
            endif
        endif
        " Setup NeoBundle
        exe 'set runtimepath=$VIMFILES,$VIMRUNTIME,'.s:neobundle_path
    endif
    let g:neobundle#types#git#clone_depth = 1
    let g:neobundle#install_max_processes  =
        \ exists('$NUMBER_OF_PROCESSORS') ? str2nr($NUMBER_OF_PROCESSORS) : 1

    function! CacheBundles() abort
        " Let NeoBundle manage NeoBundle
        NeoBundleFetch 'Shougo/neobundle.vim'
        " Local plugins for doing development
        exe 'NeoBundleLocal '.$VIMFILES.'/dev'

        NeoBundleLazy 'Shougo/vimproc.vim', {
        \   'build': {
        \       'mac':     'make -f make_mac.mak',
        \       'windows': 'tools\\update-dll-mingw'
        \}}

        " Misc
        NeoBundle 'kopischke/vim-stay'
        NeoBundleLazy 'tyru/restart.vim', {
        \   'commands': 'Restart'
        \}
        NeoBundleLazy 'tpope/vim-characterize', {
        \   'mappings': '<Plug>'
        \}
        NeoBundleLazy 'maksimr/vim-jsbeautify', {
            \ 'filetypes': ['javascript', 'html', 'css']
        \}
        NeoBundleLazy 'tpope/vim-dispatch'
        NeoBundle 'tpope/vim-projectionist', {
        \   'depends': 'tpope/vim-dispatch',
        \}
        NeoBundleLazy 'arecarn/crunch.vim', {
        \   'commands': 'Crunch',
        \   'mappings': ['<Plug>CrunchOperator', '<Plug>VisualCrunchOperator']
        \}

        " UI
        NeoBundle 'Shougo/unite.vim'
        NeoBundle 'Shougo/neomru.vim'
        NeoBundleLazy 'osyo-manga/unite-vimpatches', {
        \   'unite_sources': 'vimpatches'
        \}
        NeoBundleLazy 'osyo-manga/unite-quickfix', {
        \   'unite_sources': 'quickfix'
        \}
        NeoBundle 'mhinz/vim-startify'
        NeoBundle 'MattesGroeger/vim-bookmarks'

        " View
        " NeoBundle 'osyo-manga/vim-brightest'

        " Edit
        " NeoBundle 'cohama/lexima.vim'
        NeoBundle 'tpope/vim-commentary'
        NeoBundleLazy 'tpope/vim-surround', {
        \   'mappings': ['<Plug>Dsurround', '<Plug>Csurround']
        \}
        NeoBundleLazy 'AndrewRadev/sideways.vim', {
        \   'commands': 'Sideways',
        \   'mappings': '<Plug>'
        \}
        NeoBundleLazy 'junegunn/vim-easy-align', {
        \   'mappings': '<Plug>(EasyAlign)'
        \}
        NeoBundleLazy 'gcmt/wildfire.vim', {
        \   'mappings': '<Plug>'
        \}
        NeoBundleLazy 't9md/vim-smalls', {
        \   'mappings': '<Plug>'
        \}
        NeoBundleLazy 'saihoooooooo/glowshi-ft.vim', {
        \   'mappings': '<Plug>'
        \}
        NeoBundleLazy 'kana/vim-smartchr', {
        \   'insert': 1
        \}
        NeoBundleLazy 'Shougo/context_filetype.vim'
        NeoBundleLazy 'Shougo/neocomplete.vim', {
        \   'depends': 'Shougo/context_filetype.vim',
        \   'insert': 1
        \}
        NeoBundleLazy 'SirVer/ultisnips', {
        \   'functions': 'UltiSnips#FileTypeChanged',
        \   'insert': 1
        \}

        " Text objects
        NeoBundleLazy 'kana/vim-textobj-user'
        NeoBundleLazy 'machakann/vim-textobj-delimited', {
        \   'depends': 'kana/vim-textobj-user',
        \   'mappings': ['vid', 'viD', 'vad', 'vaD']
        \}

        " Haskell
        NeoBundleLazy 'eagletmt/ghcmod-vim', {'filetypes': 'haskell'}
        NeoBundleLazy 'eagletmt/neco-ghc',   {'filetypes': 'haskell'}
        " PHP
        NeoBundleLazy 'StanAngeloff/php.vim',       {'filetypes': 'php'}
        NeoBundleLazy '2072/PHP-Indenting-for-VIm', {'filetypes': 'php'}
        NeoBundleLazy 'shawncplus/phpcomplete.vim', {'filetypes': 'php'}
        NeoBundleLazy 'tobyS/vmustache'
        NeoBundleLazy 'tobyS/pdv', {
        \   'depends': 'tobyS/vmustache',
        \   'functions': 'pdv#DocumentWithSnip',
        \}
        " JavaScript
        NeoBundleLazy 'othree/yajs.vim',                        {'filetypes': 'javascript'}
        NeoBundleLazy 'othree/javascript-libraries-syntax.vim', {'filetypes': 'javascript'}
        NeoBundleLazy 'jiangmiao/simple-javascript-indenter',   {'filetypes': 'javascript'}
        " CSS
        NeoBundleLazy 'JulesWang/css.vim',                   {'filetypes': 'css'}
        NeoBundleLazy 'hail2u/vim-css3-syntax',              {'filetypes': 'css'}
        NeoBundleLazy 'gorodinskiy/vim-coloresque',          {'filetypes': 'css'}
        NeoBundleLazy '1995eaton/vim-better-css-completion', {'filetypes': 'css'}
        " JSON
        NeoBundleLazy 'elzr/vim-json', {'filetypes': 'json'}
        " HTML / Twig
        NeoBundleLazy 'qbbr/vim-twig',           {'filetypes': ['twig', 'html.twig']}
        NeoBundleLazy 'jbgutierrez/vim-partial', {'filetypes': ['twig', 'html.twig']}
        " CSV
        NeoBundleLazy 'chrisbra/csv.vim', {'filetypes': 'csv'}
        " SQL
        NeoBundleLazy 'shmup/vim-sql-syntax', {'filetypes': 'sql'}
        " Nginx
        NeoBundleLazy 'yaroot/vim-nginx', {'filetypes': 'nginx'}
        " VCS
        NeoBundle 'itchyny/vim-gitbranch'
        NeoBundleLazy 'cohama/agit.vim', {
        \   'commands': 'Agit'
        \}

        " NeoBundleCheck
        NeoBundleSaveCache
    endfunction

    call neobundle#begin($VIMFILES.'/bundle')
    if neobundle#has_cache()
        NeoBundleLoadCache
    else
        call CacheBundles()
    endif
    call neobundle#end()

    filetype plugin indent on
    if !exists('g:syntax_on')| syntax on |endif

" Bundle settings
"---------------------------------------------------------------------------
    if neobundle#is_installed('restart.vim')
        nmap <F9> <Esc> :<C-u>Restart<CR>
    endif

    if neobundle#is_installed('vim-startify')
        let g:startify_disable_at_vimenter = 1
        let g:startify_bookmarks = [$MYVIMRC]
        let g:startify_change_to_dir = 1
        let g:startify_change_to_vcs_root = 1
        let g:startify_session_dir = $VIMFILES.'/session'
        let g:startify_custom_indices = map(range(1,30), 'string(v:val)')
        let g:startify_list_order = ['sessions', 'bookmarks']
        nmap <silent> <F10> :<C-u>Startify<CR>
        AutocmdFT startify Autocmd WinEnter,CursorHold,CursorHoldI <buffer>
            \ setl nocursorline
    endif

    if neobundle#is_installed('crunch.vim')
        let g:crunch_result_type_append = 0
        nmap <silent> ,x <Plug>CrunchOperator_
        xmap <silent> ,x <Plug>VisualCrunchOperator
        " ,z: toggle crunch append
        nmap <silent> ,z :<C-r>={
            \ '0': 'let g:crunch_result_type_append = 1',
            \ '1': 'let g:crunch_result_type_append = 0'}[g:crunch_result_type_append]<CR><CR>
    endif

    if neobundle#is_installed('vim-bookmarks')
        let g:bookmark_sign = '##'
        let g:bookmark_auto_save_file = $VIMCACHE.'/bookmarks'
        let g:bookmark_highlight_lines = 1
        nmap <S-m>  <Plug>BookmarkToggle
        nmap ml     <Plug>BookmarkNext
        nmap mk     <Plug>BookmarkPrev
        nmap mx     <Plug>BookmarkClear
        nmap m<S-x> <Plug>BookmarkClearAll
        nmap <silent> [space]m :<C-u>BookmarkShowAll<CR>
        Autocmd VimEnter,Colorscheme *
            \ hi BookmarkLine guifg=#333333 guibg=#F5FCE5 gui=NONE
    endif

    if neobundle#is_installed('vim-easy-align')
        let g:easy_align_ignore_groups = ['Comment', 'String']
        vmap <Enter> <Plug>(EasyAlign)
    endif

    if neobundle#is_installed('vim-surround')
        let g:surround_no_mappings = 1
        let g:surround_no_insert_mappings = 1
        nmap ds <Plug>Dsurround
        nmap cs <Plug>Csurround
        nmap cS <Plug>CSurround
        " Tab: toggle quotes
        nnoremap <silent> <Tab> :<C-u>call ToggleQuote()<CR>
        function! ToggleQuote() abort
            let curline = line('.')
            let q = searchpos("'", 'n', curline)
            let qb = searchpos("'", 'bn', curline)
            let dq = searchpos('"', 'n', curline)
            let dqb = searchpos('"', 'bn', curline)
            if q[0] > 0 && qb[0] > 0 && (dq[0] == 0 || dq[0] > q[0])
                exe "normal mzcs'\"`z"
            elseif dq[0] > 0 && dqb[0] > 0
                exe "normal mzcs\"'`z"
            endif
        endfunction
    endif

    if neobundle#is_installed('vim-brightest')
        let g:brightest#enable_filetypes = {
        \   '_': 0,
        \   'php': 1,
        \   'javascript': 1
        \}
        let g:brightest#highlight = {'group': 'BrightestCursorLine'}
        let g:brightest#ignore_syntax_list = ['Comment']
        Autocmd VimEnter,Colorscheme *
            \ hi BrightestCursorLine guifg=#000000 guibg=#e6e6fa gui=NONE
    endif

    if neobundle#is_installed('lexima.vim')
        let g:lexima_no_map_to_escape = 1
        " Deleting the rule "`" (30-36)
        silent! call remove(g:lexima#default_rules, 30, -1)
    endif

    if neobundle#is_installed('sideways.vim')
       nnoremap <silent> <C-h> :SidewaysLeft<CR>
       nnoremap <silent> <C-l> :SidewaysRight<CR>
       nnoremap <silent> <S-h> :SidewaysJumpLeft<CR>
       nnoremap <silent> <S-l> :SidewaysJumpRight<CR>
    endif

    if neobundle#is_installed('vim-partial')
        AutocmdFT twig vmap <silent> <buffer> ,x :PartialExtract<CR>
    endif

    if neobundle#is_installed('vim-jsbeautify')
        AutocmdFT javascript nmap <silent> <buffer> <F1> :call JsBeautify()<CR>
        AutocmdFT html       nmap <silent> <buffer> <F1> :call HtmlBeautify()<CR>
        AutocmdFT css        nmap <silent> <buffer> <F1> :call CSSBeautify()<CR>
    endif

    if neobundle#is_installed('agit.vim')
        nmap <silent> ,g :<C-u>Agit<CR>
    endif

    if neobundle#is_installed('wildfire.vim')
        let g:wildfire_objects = {
        \   '*': split("iw iW i' i\" i) a) a] a} it i> a> vV ip"),
        \   'html,twig,xml': ["at"]
        \}
        nmap vv    <Plug>(wildfire-fuel)
        xmap vv    <Plug>(wildfire-fuel)
        xmap <C-v> <Plug>(wildfire-water)
        nmap ,v    <Plug>(wildfire-quick-select)
    endif

    if neobundle#tap('vim-commentary')
        let g:commentary_map_backslash = 0
        function! neobundle#hooks.on_source(bundle)
            unmap cgc
        endfunction
        nmap q <Plug>CommentaryLine
        vmap q <Plug>Commentary
        nmap ,q gccyypgcc
        xmap <silent> <expr> ,q 'gcgvyp`['. strpart(getregtype(), 0, 1) .'`]gc'
        call neobundle#untap()
    endif

    if neobundle#is_installed('vim-smalls')
        let g:smalls_highlight = {
        \   'SmallsCandidate'  : [['NONE', 'NONE', 'NONE'],['NONE', '#DDEECC', '#000000']],
        \   'SmallsCurrent'    : [['NONE', 'NONE', 'NONE'],['bold', '#9DBAD7', '#000000']],
        \   'SmallsJumpTarget' : [['NONE', 'NONE', 'NONE'],['NONE', '#FF7311', '#000000']],
        \   'SmallsPos'        : [['NONE', 'NONE', 'NONE'],['NONE', '#FF7311', '#000000']],
        \   'SmallsCli'        : [['NONE', 'NONE', 'NONE'],['bold', '#DDEECC', '#000000']]
        \}
        call smalls#keyboard#cli#extend_table({
        \   "\<S-Space>" : 'do_excursion',
        \   "\<A-j>"     : 'do_excursion',
        \   "\<A-k>"     : 'do_excursion',
        \   "\q"         : 'do_cancel',
        \   "\`"         : 'do_cancel'
        \})
        call smalls#keyboard#excursion#extend_table({
        \   "\q" : 'do_cancel',
        \   "\o" : 'do_set',
        \   "\`" : 'do_set',
        \   "\p" : 'do_jump'
        \})
        nmap s <Plug>(smalls)
    endif

    if neobundle#is_installed('glowshi-ft.vim')
        let g:glowshi_ft_fix_key = '[\<NL>\o]'
        let g:glowshi_ft_cancel_key = '\`'
        let g:glowshi_ft_selected_hl_guibg = '#9DBAD7'
        let g:glowshi_ft_candidates_hl_guibg = '#DDEECC'
        let g:glowshi_ft_no_default_key_mappings = 1
        map f <Plug>(glowshi-ft-f)
        map F <Plug>(glowshi-ft-F)
        map t <Plug>(glowshi-ft-t)
        map T <Plug>(glowshi-ft-T)
    endif

    if neobundle#is_installed('vim-smartchr')
        AutocmdFT haskell
            \  ImapBufExpr \ smartchr#loop('\ ', '\')
            \| ImapBufExpr - smartchr#loop('-', ' -> ', ' <- ')
        AutocmdFT php
            \  ImapBufExpr - smartchr#loop('-', '->')
            \| ImapBufExpr $ smartchr#loop('$', '$this->')
            \| ImapBufExpr > smartchr#loop('>', '=>')
            \| ImapBufExpr ; smartchr#loop(';', '::')
            \| ImapBufExpr , smartchr#loop(',', ', ')
            \| ImapBufExpr = smartchr#loop('=', ' = ', ' == ', ' === ')
        AutocmdFT javascript
            \  ImapBufExpr , smartchr#loop(',', ', ')
            \| ImapBufExpr + smartchr#loop('+', ' + ')
            \| ImapBufExpr - smartchr#loop('-', '--', '_')
            \| ImapBufExpr = smartchr#loop('=', ' = ', ' == ')
            \| ImapBufExpr $ smartchr#loop('$', 'this.', 'self.')
        AutocmdFT css
            \  ImapBufExpr ; smartchr#loop(';', ': ')
            \| ImapBufExpr % smartchr#loop('%', '% ')
            \| ImapBufExpr p smartchr#loop('p', 'px', 'px ')
        AutocmdFT yaml
            \  ImapBufExpr > smartchr#loop('>', '%>')
            \| ImapBufExpr < smartchr#loop('<', '<%', '<%=')
    endif

    if neobundle#tap('neocomplete.vim')
        let g:neocomplete#enable_at_startup = 1
        let g:neocomplete#enable_smart_case = 0
        let g:neocomplete#enable_camel_case = 1
        " let g:neocomplete#enable_insert_char_pre = 1
        let g:neocomplete#enable_refresh_always = 1
        let g:neocomplete#enable_auto_select = 0
        let g:neocomplete#max_list = 7
        let g:neocomplete#force_overwrite_completefunc = 1
        let g:neocomplete#auto_completion_start_length = 2
        let g:neocomplete#sources#syntax#min_keyword_length = 3
        let g:neocomplete#data_directory = $VIMCACHE.'/neocomplete'
        " Completion patterns
        let g:neocomplete#sources#omni#input_patterns = get(g:, 'neocomplete#sources#omni#input_patterns', {})
        let g:neocomplete#sources#omni#input_patterns.php =
            \ '\h\w*\|[^. \t]->\%(\h\w*\)\?\|\h\w*::\%(\h\w*\)\?'
        let g:neocomplete#force_omni_input_patterns = get(g:, 'neocomplete#force_omni_input_patterns', {})
        let g:neocomplete#force_omni_input_patterns.php =
            \ '[^. \t]->\|\h\w*::\|\(new\|use\|extends\|implements\|instanceof\)\s'
        let g:neocomplete#force_omni_input_patterns.javascript = '[^. \t]\.\%(\h\w*\)\?'
        let g:neocomplete#force_omni_input_patterns.css = '[[:alpha:]_:-][[:alnum:]_:-]*'
        let g:neocomplete#force_omni_input_patterns.sql = '[^.[:digit:] *\t]\%(\.\)\%(\h\w*\)\?'
        " Alias filetypes
        let g:neocomplete#same_filetypes = get(g:, 'neocomplete#same_filetypes', {})
        let g:neocomplete#same_filetypes.html  = 'css'

        " Tab: completion
        imap <expr> <Tab>   pumvisible() ? "\<C-n>" : CheckBackSpace() ? "\<Tab>" : neocomplete#start_manual_complete()
        imap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<C-x>\<C-o>"
        imap <expr> <C-j>   pumvisible() ? "\<C-n>" : "\<C-j>"
        imap <expr> <C-k>   pumvisible() ? "\<C-p>" : "\<C-k>"

        function! CheckBackSpace() abort
            let col = col('.') - 1
            return !col || getline('.')[col-1] =~ '\s'
        endfunction
    endif

    if neobundle#is_installed('ultisnips')
        let g:UltiSnipsExpandTrigger = '`'
        let g:UltiSnipsListSnippets = '<F4>'
        let g:UltiSnipsJumpForwardTrigger = '<Tab>'
        let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'
        let g:UltiSnipsSnippetsDir = $VIMFILES.'/dev/dotvim/ultisnips'
        Autocmd BufNewFile,BufRead *.snippets setl filetype=snippets
    endif

    if neobundle#is_installed('unite.vim')
        let g:unite_source_history_yank_enable = 0
        let g:unite_source_rec_max_cache_files = -1
        let g:unite_source_buffer_time_format = '%H:%M '
        let g:unite_data_directory = $VIMCACHE.'/unite'
        " Search tool
        let g:unite_source_grep_command = s:search_tool
        let g:unite_source_grep_recursive_opt = ''
        let g:unite_source_grep_encoding = 'utf-8'
        let g:unite_source_grep_default_opts = '--follow --smart-case --nogroup --nocolor'
        if executable('ag')
            let g:unite_source_rec_async_command = 'ag'
                \.  ' '. join(map(split(g:ignore_ext, ','), '"\--ignore *.".v:val.""'), ' ')
                \.  ' '. join(map(split(g:ignore_dir, ','), '"\--ignore ".v:val.""'), ' ')
                \. (&smartcase ? ' -S' : ''). ' -l --nogroup --nocolor --depth 6 .'
        endif

        " Default profile
        let default_context = {
        \   'winheight': 10,
        \   'direction': 'below',
        \   'prompt_direction': 'top',
        \   'cursor_line_time': '0.0',
        \   'short_source_names': 1
        \}
        " Quickfix profile
        let quickfix_context = {
        \   'winheight': 16,
        \   'no_quit': 1,
        \   'keep_focus': 1
        \}
        " Line profile
        let line_context = {
        \   'winheight': 20
        \}

        " Custom profiles
        call unite#custom#profile('default', 'context', default_context)
        call unite#custom#profile('source/line,source/grep', 'context', line_context)
        call unite#custom#profile('source/quickfix,source/location_list', 'context', quickfix_context)

        " Custom filters
        call unite#custom#source('file_rec/async', 'max_candidates', 500)
        call unite#custom#source('file_rec/async,line', 'sorters', 'sorter_rank')
        call unite#custom#source('file_rec/async',
            \ 'matchers', ['converter_relative_word', 'matcher_fuzzy'])
        " Sort buffers by number
        call unite#custom#source('buffer', 'sorters', 'sorter_reverse')

        " Custom actions
        call unite#custom#default_action('directory,neomru/directory', 'lcd')

        " Unite tuning
        AutocmdFT unite setl nolist guicursor=a:blinkon0
        AutocmdFT unite Autocmd InsertEnter,InsertLeave <buffer>
            \ setl nonu nornu nolist colorcolumn=""
        " Obliterate unite buffers (marks especially)
        " Autocmd BufLeave \[unite\]* if &buftype ==# 'nofile'| setl bufhidden=wipe |endif

        AutocmdFT unite call UniteMySettings()
        function! UniteMySettings() abort
            " Normal mode
            nmap <buffer> q         <Plug>(unite_exit)
            nmap <buffer> `         <Plug>(unite_exit)
            nmap <buffer> gg        <Plug>(unite_cursor_top)
            nmap <buffer> <S-Space> <Plug>(unite_insert_enter)
            nmap <buffer> <S-Tab>   <Plug>(unite_loop_cursor_up)
            nmap <buffer> <Tab>     <Plug>(unite_loop_cursor_down)
            nmap <buffer> p         <Plug>(unite_quick_match_default_action)
            nmap <silent> <buffer> <expr> cd unite#do_action('cd')
            nmap <silent> <buffer> <expr> o unite#smart_map('o', unite#do_action('open'))
            nmap <silent> <buffer> <expr> s unite#smart_map('s', unite#do_action('split'))
            nmap <silent> <buffer> <expr> v unite#smart_map('v', unite#do_action('vsplit'))
            nmap <silent> <buffer> <expr> t unite#smart_map('t', unite#do_action('tabopen'))
            nmap <silent> <buffer> <expr> r unite#smart_map('r', unite#do_action('rename'))
            nmap <silent> <buffer> <expr> ' unite#smart_map('x', "\<Plug>(unite_quick_match_choose_action)")

            " Insert mode
            imap <buffer> <expr> q getline('.')[col('.')-2] ==# 'q' ? "\<Esc>\<Plug>(unite_exit)" : 'q'
            imap <buffer> `         <Plug>(unite_exit)
            imap <buffer> gg   <Esc><Plug>(unite_cursor_top)
            imap <buffer> <S-Space> <Plug>(unite_insert_leave)
            imap <buffer> ;         <Plug>(unite_insert_leave)
            imap <buffer> <Tab>     <Plug>(unite_select_next_line)
            imap <buffer> <S-Tab>   <Plug>(unite_select_previous_line)
            imap <buffer> <A-j>     <Plug>(unite_select_next_line)
            imap <buffer> <A-k>     <Plug>(unite_select_previous_line)
            imap <buffer> <C-Space> <Plug>(unite_delete_backward_path)
            imap <buffer> '         <Plug>(unite_quick_match_default_action)
            imap <silent> <buffer> <expr> o unite#smart_map('o', unite#do_action('open'))
            imap <silent> <buffer> <expr> s unite#smart_map('s', unite#do_action('split'))
            imap <silent> <buffer> <expr> v unite#smart_map('v', unite#do_action('vsplit'))
            imap <silent> <buffer> <expr> t unite#smart_map('t', unite#do_action('tabopen'))

            " Command mode
            cmap <buffer> ` <Esc>
        endfunction

        " Space-d: open directories
        nmap <silent> [space]d :<C-u>Unite directory<CR>
        " Space-b: open buffers
        nmap <silent> [space]b :<C-u>Unite buffer<CR>
        " Space-h: open windows
        nmap <silent> [space]h :<C-u>Unite window<CR>
        " Space-t: open tab pages
        nmap <silent> <expr> [space]t ":\<C-u>Unite tab -select=".(tabpagenr()-1)."\<CR>"

        " Space-f: open files
        nmap <silent> [space]f :<C-u>Unite file_rec/async -start-insert<CR>
        " Space-n: create a new file
        nmap <silent> [space]F :<C-u>Unite file/new -start-insert<CR>

        " /: search
        nmap <silent> / :<C-u>Unite line:forward:wrap -no-split -start-insert<CR>
        " Space-g: grep search
        nmap <silent> [space]g :<C-u>Unite grep:. -auto-preview<CR>
        " *: search keyword under the cursor
        nmap <silent> <expr> *
            \ ":\<C-u>UniteWithCursorWord line:forward:wrap -buffer-name=search-".bufnr('%')."\<CR>"
        " Space-r: resume search buffer
        nmap <silent> <expr> [space]r
            \ ":\<C-u>UniteResume search-".bufnr('%')." -no-start-insert -force-redraw\<CR>"

        " Space-o: open message log
        nmap <silent> [space]o :<C-u>Unite output:message<CR>
        " Space-i: NeoBundle update
        nmap <silent> [space]i :<C-u>Unite neobundle/update
            \ -buffer-name=neobundle -no-split -no-start-insert -multi-line -max-multi-lines=1 -log<CR>
    endif

    if neobundle#is_installed('neomru.vim')
        let g:neomru#file_mru_path = $VIMCACHE.'/unite/file'
        let g:neomru#file_mru_ignore_pattern = '[._]vimrc$'
        let g:neomru#filename_format = ':~:.'
        let g:neomru#directory_mru_path = $VIMCACHE.'/unite/directory'
        let g:neomru#time_format = ' %d.%m %H:%M — '
        call unite#custom#source('neomru/file,neomru/directory', 'limit', 30)
        " Space-l: open recently-opened files
        nmap <silent> [space]l :<C-u>Unite neomru/file<CR>
        " Space-L: open recently-opened directories
        nmap <silent> [space]L :<C-u>Unite neomru/directory<CR>
    endif

    if neobundle#is_installed('unite-vimpatches')
        " Space-p: open vimpatches log
        nmap <silent> [space]p :<C-u>Unite vimpatches<CR>
    endif

" Languages
"---------------------------------------------------------------------------
" Haskell
    AutocmdFT haskell Indent 4
    AutocmdFT cabal   Indent 2
    " Syntax
    AutocmdFT haskell setl iskeyword+='
    AutocmdFT haskell setl commentstring=--\ %s
    " Autocomplete
    if neobundle#tap('neco-ghc')
        function! neobundle#hooks.on_source(bundle)
            let g:necoghc_enable_detailed_browse = 1
        endfunction
        AutocmdFT haskell setl omnifunc=necoghc#omnifunc
        call neobundle#untap()
    endif

" PHP
    AutocmdFT php Indent 4
    " Syntax
    AutocmdFT php Autocmd BufEnter <buffer>
        \  hi link phpDocTags  phpDefine
        \| hi link phpDocParam phpType
    " Autocomplete
    if neobundle#tap('phpcomplete.vim')
        function! neobundle#hooks.on_source(bundle)
            let g:phpcomplete_relax_static_constraint = 1
            let g:phpcomplete_parse_docblock_comments = 1
            let g:phpcomplete_search_tags_for_variables = 1
            let g:phpcomplete_complete_for_unknown_classes = 0
        endfunction
        AutocmdFT php setl omnifunc=phpcomplete#CompletePHP
        call neobundle#untap()
    endif
    " PHP Documentor
    if neobundle#tap('pdv')
        function! neobundle#hooks.on_source(bundle)
            let g:pdv_template_dir = $VIMFILES.'/bundle/pdv/templates_snip'
        endfunction
        AutocmdFT php
            \ nmap <silent> <buffer> ,c :call pdv#DocumentWithSnip()<CR>
        call neobundle#untap()
    endif

" JavaScript
    AutocmdFT javascript Indent 4
    " Syntax
    if neobundle#tap('javascript-libraries-syntax')
        function! neobundle#hooks.on_source(bundle)
            let g:used_javascript_libs = 'angularjs,jquery'
        endfunction
        call neobundle#untap()
    endif
    if neobundle#tap('simple-javascript-indenter')
        function! neobundle#hooks.on_source(bundle)
            let g:SimpleJsIndenter_BriefMode = 1
            let g:SimpleJsIndenter_CaseIndentLevel = -1
        endfunction
        call neobundle#untap()
    endif

" HTML
    AutocmdFT html Indent 2
    AutocmdFT html iabbrev <buffer> & &amp;
    " Autocomplete
    AutocmdFT html setl omnifunc=htmlcomplete#CompleteTags

" CSS
    AutocmdFT css setl nowrap | Indent 2
    " Syntax
    AutocmdFT css setl iskeyword+=-,%
    " Autocomplete
    AutocmdFT css setl omnifunc=csscomplete#CompleteCSS

" Twig
    AutocmdFT twig,twig.html Indent 2

" JSON
    " Syntax
    if neobundle#tap('vim-json')
        function! neobundle#hooks.on_source(bundle)
            let g:vim_json_syntax_concealcursor = 'inc'
        endfunction

        Autocmd InsertEnter *.json setl concealcursor=
        Autocmd InsertLeave *.json setl concealcursor=inc
        AutocmdFT json
            \ nmap <buffer> <silent> ,c :<C-r>={
            \   '0': 'setl conceallevel=2',
            \   '2': 'setl conceallevel=0'}[&conceallevel]<CR><CR>

        call neobundle#untap()
    endif

" Yaml
    AutocmdFT yaml setl nowrap | Indent 4

" XML
    AutocmdFT xml setl nowrap | Indent 4
    " Autocomplete
    AutocmdFT xml setl omnifunc=xmlcomplete#CompleteTags

" Nginx
    Autocmd BufNewFile,BufRead *.conf setl filetype=nginx commentstring=#%s

" Vim
    AutocmdFT vim setl iskeyword+=:

" GUI
"---------------------------------------------------------------------------
    if has('gui_running')
        set guioptions=a
        set guicursor=n-v:blinkon0  " turn off blinking the cursor
        set linespace=3             " extra spaces between rows
        " Window size and position
        if has('vim_starting')
            winsize 176 40 | winpos 492 280
            " winsize 140 46 | winpos 360 224
        endif
    endif

    " Font
    if WINDOWS()
        set guifont=Droid_Sans_Mono:h10,Consolas:h11
    else
        set guifont=Droid\ Sans\ Mono\ 10,Consolas\ 11
    endif

    " DirectWrite
    if WINDOWS() && has('directx')
        set renderoptions=type:directx,gamma:2.2,contrast:0.5,level:0.0,geom:1,taamode:1,renmode:3
    endif

" View
"---------------------------------------------------------------------------
    " Don't override colorscheme on reloading
    if !exists('g:colors_name')| silent! colorscheme topos |endif
    " Reload the colorscheme whenever we write the file
    exe 'Autocmd BufWritePost '.g:colors_name.'.vim colorscheme '.g:colors_name

    set cursorline               " highlight the current line
    set relativenumber           " show the line number
    set shortmess=aoOtTI         " shortens messages to avoid 'press a key' prompt
    set hidden                   " allows the closing of buffers without saving
    set switchbuf=useopen,split  " orders to open the buffer
    set showtabline=1            " always show the tab pages
    set winminheight=0           " minimal height of a window
    set noequalalways            " resize windows as little as possible
    set splitbelow splitright    " splitting a window below/right the current one

    " Diff
    set diffopt=iwhite,vertical

    " Fold
    set nofoldenable

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
    endif

    " Highlight invisible symbols
    set list listchars=precedes:<,extends:>,nbsp:.,tab:+-,trail:•
    " Avoid showing trailing whitespace when in Insert mode
    let s:trailchar = matchstr(&listchars, '\(trail:\)\@<=\S')
    Autocmd InsertEnter * exe 'setl listchars-=trail:'. s:trailchar
    Autocmd InsertLeave * exe 'setl listchars+=trail:'. s:trailchar

    " Ignore pattern
    let &suffixes = join(map(split(g:ignore_ext, ','), '",.".v:val.""'), '')
    let &wildignore = g:ignore_dir

    " Title-line
    set titlestring=%t\ (%{expand(\'%:p:.:h\')}/)

    " Command-line
    set cmdheight=1  " height of command line
    set noshowcmd    " don't show command on statusline
    set noshowmode   " don't show the mode ("-- INSERT --") at the bottom
    set wildmenu wildmode=longest:full,full

    " Status-line
    set laststatus=2
    " Format the statusline
    let &statusline =
    \  "%1* %l%*.%L %*"
    \. "%1*%(#%{winbufnr(0)}\ %)%*"
    \. "%(%{exists('*GitStatus()') ? GitStatus() : ''}\ %)"
    \. "%-0.50f "
    \. "%2*%(%{exists('*BufModified()') ? BufModified() : ''}\ %)%*"
    \. "%="
    \. "%(%{exists('*FileModTime()') ? FileModTime() : ''}\ %)"
    \. "%(%{exists('*FileSize()') ? FileSize() : ''}\ %)"
    \. "%2*%(%{&paste ? '[P]' : ''}\ %)%*"
    \. "%2*%(%{&iminsert ? 'RU' : 'EN'}\ %)%*"
    \. "%(%{&fileencoding == '' ? &encoding : &fileencoding}\ %)"
    \. "%2*%(%Y\ %)%*"

    " Status-line functions
    function! BufModified() abort
        return getbufvar(winbufnr(0), '&modified') ? '+' : ''
    endfunction

    function! FileSize() abort
        let bytes = getfsize(expand('%:p'))
        if bytes <= 0| return '' |endif
        return bytes < 1024 ? bytes.'B' : (bytes / 1024).'K'
    endfunction

    function! FileModTime() abort
        let file = expand('%:p')
        return filereadable(file) ? strftime('%H:%M:%S %d%m[%y]', getftime(file)) : ''
    endfunction

    function! GitStatus() abort
        return exists('*gitbranch#name()') && gitbranch#name() !=# '' ?
                    \ printf('[%s]', gitbranch#name()) : ''
    endfunction

" Edit
"---------------------------------------------------------------------------
    set report=0           " reporting number of lines changes
    set lazyredraw         " don't redraw while executing macros
    set nostartofline      " avoid moving cursor to BOL when jumping around
    set virtualedit=all    " allows the cursor position past true end of line
    set clipboard=unnamed  " use * register for copy-paste

    " Keymapping timeout (mapping / keycode)
    set notimeout ttimeoutlen=100
    " set timeoutlen=2000 ttimeoutlen=100

    " Indent
    set cindent          " smart indenting for c-like code
    set autoindent       " indent at the same level of the previous line
    set shiftround       " indent multiple of shiftwidth
    set expandtab        " spaces instead of tabs
    set tabstop=4        " number of spaces per tab for display
    set shiftwidth=4     " number of spaces per tab in insert mode
    set softtabstop=4    " number of spaces when indenting
    set nojoinspaces     " Prevents inserting two spaces after punctuation on a join (J)

    " Backspacing settings
    " indent  allow backspacing over autoindent
    " eol     allow backspacing over line breaks (join lines)
    " start   allow backspacing over the start of insert;
    "         CTRL-W and CTRL-U stop once at the start of insert
    set backspace=indent,eol,start

    " Search
    set hlsearch         " highlight search results
    set incsearch        " find as you type search
    set ignorecase       " case insensitive search
    set smartcase        " case sensitive when uc present
    set magic            " change the way backslashes are used in search patterns
    " set gdefault         " flag 'g' by default for replacing

    " Autocomplete
    set complete-=i
    set completeopt=longest
    set pumheight=15
    " Do not display completion messages
    Autocmd VimEnter,Colorscheme *
        \  hi ModeMsg guifg=bg guibg=bg gui=NONE
        \| hi Quesion guifg=bg guibg=bg gui=NONE
    " Syntax complete if nothing else available
    Autocmd BufEnter,WinEnter * if &omnifunc == ''| setl omnifunc=syntaxcomplete#Complete |endif

" Shortcuts
"---------------------------------------------------------------------------
    " Insert the current file
    ab ##f <C-r>=expand('%:t:r')<CR>
    ca ##f <C-r>=expand('%:t:r')<CR>
    " Insert the current file path
    ab ##p <C-r>=expand('%:p')<CR>
    ca ##p <C-r>=expand('%:p')<CR>
    " Insert the current file directory
    ab ##d <C-r>=expand('%:p:h').'\'<CR>
    ca ##d <C-r>=expand('%:p:h').'\'<CR>
    " Inset the current timestamp
    ab ##t <C-r>=strftime('%Y-%m-%d')<CR>
    ca ##t <C-r>=strftime('%Y-%m-%d')<CR>
    " Inset the current Unix time
    ab ##l <C-r>=localtime()<CR>
    ca ##l <C-r>=localtime()<CR>

" The prefix keys
"---------------------------------------------------------------------------
    " [space]
    nmap <Space> [space]
    xmap <Space> [space]
    nnoremap [space] <Nop>
    xnoremap [space] <Nop>

" Normal mode
"---------------------------------------------------------------------------
    " jk: don't skip wrap lines
    nmap <expr> j v:count ? 'j' : 'gj'
    nmap <expr> k v:count ? 'k' : 'gk'
    " Alt-[jkhl]: move selected lines
    nmap <A-j> ddp
    nmap <A-k> ddkP
    nmap <A-h> <<<Esc>
    nmap <A-l> >>><Esc>
    " Ctrl-[jk]: scroll up/down
    nmap <expr> <C-j> max([winheight(0)-2, 1]). "\<C-d>" .(line('w$') >= line('$') ? 'L' : 'H')
    nmap <expr> <C-k> max([winheight(0)-2, 1]). "\<C-u>" .(line('w0') <= 1         ? 'H' : 'L')
    " Q: auto indent text
    nmap Q ==
    " Y: yank line
    nnoremap Y y$
    " [xXcC]: delete to black hole register
    nnoremap x "_x
    nnoremap X "_dd
    nnoremap c "_c
    nnoremap C "_C

    " m-w: save file
    nmap <silent> mw <Esc> :write!<CR>
    " me: reopen file
    nmap <silent> me <Esc> :edit!<CR>
    " mt: create tab
    nmap <silent> mt <Esc> :tabnew<CR>
    " mq: close tab
    nmap <silent> mq <Esc> :tabclose!<CR>
    " mr: tab next
    nmap <silent> mr <Esc> :tabnext<CR>
    nmap <silent> [space]k <Esc> :tabnext<CR>
    " mv: tab prev
    nmap <silent> mv <Esc> :tabprev<CR>
    nmap <silent> [space]j <Esc> :tabprev<CR>
    " md: close buffer
    nmap <silent> md <Esc> :bdelete!<CR>
    " ma: next window
    nmap ma <Esc> <C-w>w
    nmap <F2> <C-w>w
    " mh: split window horizontaly
    " nmap mh <C-w>s
    " mv: split window verticaly
    " nmap mv <C-w>v
    " ,ev: open .vimrc in a new tab
    nmap ,ev :tabnew $MYVIMRC<CR>

    " m-c: clear highlight after search
    nmap <silent> mc <Esc> :nohl<CR>:let @/=""<CR>
    " Ctrl+c: old clear highlight after search
    nmap <silent> <C-c> <Esc> :nohl<CR>:let @/=""<CR>

    " [meta] + 1-9: jumps to tab
    for n in range(1, 9)
        exe printf('nmap <silent> m%d %dgt', n, n)
        exe printf('nmap <silent> [space]%d %dgt', n, n)
    endfor

    " Test
    nmap <silent> <Enter>   :tabnext<CR>
    nmap <silent> <S-Enter> :tabprev<CR>
    nmap <silent> <C-Enter> :bdelete!<CR>

    " Unbinds
    nmap <F1> <Nop>
    nmap v<S-k> <Nop>
    nmap <Space><S-k> <Nop>

" Insert mode
"---------------------------------------------------------------------------
    " Alt-[jkhl]: standart move
    imap <A-j> <C-o>gj
    imap <A-h> <C-o>h
    imap <A-k> <C-o>gk
    imap <A-l> <C-o>l
    " jj: fast Esc
    imap jj <Esc>`^
    " Alt-a: jump to head
    imap <A-a> <C-o>I
    " Alt-e: jump to end
    imap <A-e> <C-o>A
    " Alt-b: jump back to beginning of previous word
    imap <A-b> <Esc>Bi
    " Alt-q: jump to first char
    imap <A-q> <Home>
    " Alt-d: delete char
    imap <A-d> <Del>
    " Alt-m: break line above
    imap <A-m> <Esc><S-o>
    " Alt-n: break line below
    imap <A-n> <C-m>
    " Alt-r: change language
    imap <A-r> <C-^>
    " Ctrl-v: paste
    imap <C-v> <S-Insert>
    " qq: smart fast Esc
    imap <expr> q getline('.')[col('.')-2] ==# 'q' ? "\<BS>\<Esc>`^" : 'q'
    " Ctrl-c: old fast Esc
    imap <C-c> <Esc>`^

" Visual mode
"---------------------------------------------------------------------------
    " jk: don't skip wrap lines
    xmap j gj
    xmap k gk
    " Alt-[jkhl]: move selected lines
    xnoremap <A-j> xp'[V']
    xnoremap <A-k> xkP'[V']
    xnoremap <A-h> <'[V']
    xnoremap <A-l> >'[V']
    " Q: auto indent text
    xmap Q ==<Esc>
    " Space: fast Esc
    xmap <Space> <Esc>
    " Alt-w: fast save
    xmap <silent> <A-w> :update<CR>
    " Ctrl-s: old fast save
    xmap <C-s> <Esc>:w!<CR>
    " Ctrl-[jk]: scroll up/down
    xmap <expr> <C-j> max([winheight(0)-2, 1]). "\<C-d>" .(line('w$') >= line('$') ? 'L' : 'H')
    xmap <expr> <C-k> max([winheight(0)-2, 1]). "\<C-u>" .(line('w0') <= 1         ? 'H' : 'L')
    " .: repeat command for each line
    xnoremap . :normal .<CR>
    " [yY]: keep cursor position when yanking
    xnoremap <silent> <expr> y 'ygv' . mode()
    xnoremap <silent> <expr> Y 'Ygv' . mode()
    " [xXcC]: delete to black hole register
    xnoremap x "_x
    xnoremap X "_X
    xnoremap c "_c
    xnoremap C "_C

" Command mode
"---------------------------------------------------------------------------
    " Ctrl-h: previous char
    cmap <C-h> <Left>
    " Ctrl-l: next char
    cmap <C-l> <Right>
    " Ctrl-h: previous word
    cmap <A-h> <S-left>
    " Ctrl-h: next word
    cmap <A-l> <S-right>
    " Ctrl-j: previous history
    cmap <C-j> <Down>
    " Ctrl-k: next history
    cmap <C-k> <Up>
    " Ctrl-d: delete char
    cmap <A-d> <Del>
    " Ctrl-a: jump to head
    cmap <C-a> <Home>
    " Ctrl-e: jump to end
    cmap <C-e> <End>
    " jj: smart fast Esc
    cmap <expr> j getcmdline()[getcmdpos()-2] ==# 'j' ? "\<C-c>" : 'j'
    " qq: smart fast Esc
    cmap <expr> q getcmdline()[getcmdpos()-2] ==# 'q' ? "\<C-c>" : 'q'
    " `: old fast Esc
    cmap <silent> ` <C-c>

" Experimental
"---------------------------------------------------------------------------
    " ,p: toggle paste mode
    nmap <silent> ,p :<C-r>={
        \ '0': 'set paste',
        \ '1': 'set nopaste'}[&paste]<CR><CR>
    " ,d: diff this
    nmap <silent> <expr> ,d ":\<C-u>".(&diff ? 'diffoff' : 'diffthis')."\<CR>"
    " ,r: search and replace word under cursor
    nmap ,r :%s/\<<C-r>=expand('<cword>')<CR>\>/
    " ,f: display all lines with keyword under cursor
    nmap ,f [I:let nr = input('Which one: ')<Bar>exe 'normal '. nr .'[\t'<CR>
    " This should preserve your last yank/delete as well.
    nmap zl :let @z=@"<CR>x$p:let @"=@z<CR>
    " Change word and repeat for next or previous with .
    nmap ,c *``cgn
    nmap ,C #``cgN
    " Tab: toggle case conversion
    xmap <silent> <Tab> y:call CaseConversion()<CR>
    function! CaseConversion() abort
        " snake_case -> kebab-case -> camelCase -> MixedCase
        let word = @"
        if word =~# '^[a-z0-9_]\+[!?]\?$'
            let @" = substitute(word, '_', '-', 'g')
        elseif word =~# '^[a-z0-9?!-]\+[!?]\?$'
            let @" = substitute(word, '\C-\([^-]\)', '\u\1', 'g')
        elseif word =~# '^[a-z0-9]\+\([A-Z][a-z0-9]*\)\+[!?]\?$'
            let @" = toupper(word[0]) . strpart(word, 1)
        elseif word =~# '^\([A-Z][a-z0-9]*\)\{2,}[!?]\?$'
            let @" = strpart(substitute(word, '\C\([A-Z]\)', '_\l\1', 'g'), 1)
        else
            normal gv
        endif
        let e = col("'>") + len(@") - len(word)
        exe "normal gv\"_c\<C-r>\"\<Esc>".col("'<"). "|v" . e . '|'
    endfunction
