" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#info#init_buffer() abort " {{{1
  command! -buffer -bang VimtexInfo call vimtex#info#open(<q-bang> == '!')

  nnoremap <buffer> <plug>(vimtex-info)      :VimtexInfo<cr>
  nnoremap <buffer> <plug>(vimtex-info-full) :VimtexInfo!<cr>
endfunction

" }}}1
function! vimtex#info#open(global) abort " {{{1
  let s:info.global = a:global
  call vimtex#scratch#new(s:info)
endfunction

" }}}1


let s:info = {
      \ 'name' : 'VimtexInfo',
      \ 'global' : 0,
      \}
function! s:info.print_content() abort dict " {{{1
  for l:line in self.gather_system_info()
    call append('$', l:line)
  endfor
  call append('$', '')
  for l:line in self.gather_state_info()
    call append('$', l:line)
  endfor
endfunction

" }}}1
function! s:info.gather_system_info() abort dict " {{{1
  let l:lines = [
        \ 'System info:',
        \ '  OS: ' . s:get_os_info(),
        \ '  LaTeX version: ' . s:get_latex_info(),
        \ '  Vim version: ' . s:get_vim_info(),
        \]

  if has('clientserver') || has('nvim')
    call add(l:lines, '  Has clientserver: true')
    call add(l:lines, '  Servername: '
          \ . (empty(v:servername) ? 'undefined (vim started without --servername)' : v:servername))
  else
    call add(l:lines, '  Has clientserver: false')
  endif

  call add(l:lines, '  $PATH:')
  for l:path in uniq(sort(split($PATH, '[:;]')))
    call add(l:lines, '    - ' .. l:path)
  endfor

  return l:lines
endfunction

" }}}1
function! s:info.gather_state_info() abort dict " {{{1
  if self.global
    let l:lines = []
    for l:data in vimtex#state#list_all()
      let l:lines += s:get_info(l:data)
      let l:lines += ['']
    endfor
    call remove(l:lines, -1)
  else
    let l:lines = s:get_info(b:vimtex)
  endif

  return l:lines
endfunction

" }}}1
function! s:info.syntax() abort dict " {{{1
  syntax match VimtexInfoOther /.*/
  syntax match VimtexInfoKey /^.\{-}:/ nextgroup=VimtexInfoValue
  syntax match VimtexInfoValue /.*/ contained
  syntax match VimtexInfoTitle /VimTeX project:/ nextgroup=VimtexInfoValue
  syntax match VimtexInfoTitle /System info/
endfunction

" }}}1

"
" Functions to parse the VimTeX state data
"
function! s:get_info(item, ...) abort " {{{1
  if empty(a:item) | return [] | endif
  let l:indent = a:0 > 0 ? a:1 : 0

  if type(a:item) == v:t_dict
    return s:parse_dict(a:item, l:indent)
  endif

  if type(a:item) == v:t_list
    let l:entries = []
    for [l:title, l:Value] in a:item
      if type(l:Value) == v:t_dict
        call extend(l:entries, s:parse_dict(l:Value, l:indent, l:title))
      elseif type(l:Value) == v:t_list
        call extend(l:entries, s:parse_list(l:Value, l:indent, l:title))
      else
        call add(l:entries,
              \ repeat('  ', l:indent) . printf('%s: %s', l:title, l:Value))
      endif
      unlet l:Value
    endfor
    return l:entries
  endif
endfunction

" }}}1
function! s:parse_dict(dict, indent, ...) abort " {{{1
  if empty(a:dict) | return [] | endif
  let l:dict = a:dict
  let l:indent = a:indent
  let l:entries = []

  if a:0 > 0
    let l:title = a:1
    let l:name = ''
    if has_key(a:dict, 'name')
      let l:dict = deepcopy(a:dict)
      let l:name = remove(l:dict, 'name')
    endif
    call add(l:entries,
          \ repeat('  ', l:indent) . printf('%s: %s', l:title, l:name))
    let l:indent += 1
  endif

  let l:items = has_key(l:dict, '__pprint')
        \ ? l:dict.__pprint() : items(l:dict)

  return extend(l:entries, s:get_info(l:items, l:indent))
endfunction

" }}}1
function! s:parse_list(list, indent, title) abort " {{{1
  if empty(a:list) | return [] | endif

  let l:entries = []
  let l:indent = repeat('  ', a:indent)
  if type(a:list[0]) == v:t_list
    let l:name = ''
    let l:index = 0

    " l:entry[0] == title
    " l:entry[1] == value
    for l:entry in a:list
      if l:entry[0] ==# 'name'
        let l:name = l:entry[1]
        break
      endif
      let l:index += 1
    endfor

    if empty(l:name)
      let l:list = a:list
    else
      let l:list = deepcopy(a:list)
      call remove(l:list, l:index)
    endif

    call add(l:entries, l:indent . printf('%s: %s', a:title, l:name))
    call extend(l:entries, s:get_info(l:list, a:indent+1))
  else
    call add(l:entries, l:indent . printf('%s:', a:title))
    for l:value in a:list
      call add(l:entries, l:indent . printf('  %s', l:value))
    endfor
  endif

  return l:entries
endfunction

" }}}1

"
" Other utility functions
"
function! s:get_os_info() abort " {{{1
  let l:os = vimtex#util#get_os()

  if l:os ==# 'linux'
    let l:result = executable('lsb_release')
        \ ? vimtex#jobs#cached('lsb_release -d')[0][12:]
        \ : vimtex#jobs#cached('uname -sr')[0]
    return substitute(l:result, '^\s*', '', '')
  elseif l:os ==# 'mac'
    if executable('sw_vers')
      let l:name = vimtex#jobs#cached('sw_vers -productName')[0]
      let l:version = vimtex#jobs#cached('sw_vers -productVersion')[0]
      let l:build = vimtex#jobs#cached('sw_vers -buildVersion')[0]
      return l:name . ' ' . l:version . ' (' . l:build . ')'
    else
      return 'MacOS/i[Pad]OS'
    endif
  else
    let l:win_info = vimtex#jobs#cached('systeminfo')

    try
      let l:name = trim(matchstr(l:win_info[1], ':\s*\zs.*'))
      let l:version = trim(matchstr(l:win_info[2], ':\s*\zs.*'))
      return l:name . ' (' . l:version . ')'
    catch
      return 'Windows (' . string(l:win_info) . ')'
    endtry
  endif
endfunction

" }}}1
function! s:get_latex_info() abort " {{{1
  let l:result = executable('latex')
      \ ? vimtex#jobs#capture('latex --version')[0]
      \ : 'LATEX WAS NOT FOUND!'

  return l:result
endfunction

" }}}1
function! s:get_vim_info() abort " {{{1
  let l:info = vimtex#util#command('version')

  if has('nvim')
    return l:info[0]
  else
    let l:version = 'VIM ' . strpart(l:info[0], 18, 3) . ' ('
    let l:index = 2 - (l:info[1] =~# ':\s*\d')
    let l:version .= matchstr(l:info[l:index], ':\s*\zs.*') . ')'
    return l:version
  endif
endfunction

" }}}1
