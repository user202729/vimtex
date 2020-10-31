" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tikz#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'tikz') | return | endif
  let b:vimtex_syntax.tikz = 1

  syntax cluster texClusterTikz contains=texEnvBgnTikz,texCmdEnv,texCmd,texTikzSemicolon,texComment,texMatcher
  syntax cluster texClusterTikzset contains=texArgTikzset,texOptSep,texOptEqual,texRegionMathX,texTypeSize,texCmd,texLength,texComment

  syntax match texCmd /\\tikzset\>/ skipwhite skipnl nextgroup=texArgTikzset
  call vimtex#syntax#core#new_cmd_arg('texArgTikzset', '', '@texClusterTikzset')

  syntax match texEnvBgnTikz /\v\\begin\{tikzpicture\}/
        \ nextgroup=texOptTikzpic skipwhite skipnl contains=texCmdEnv
  syntax region texRegionTikz
        \ start='\\begin{tikzpicture}'
        \ end='\\end{tikzpicture}'
        \ keepend transparent contains=@texClusterTikz
  call vimtex#syntax#core#new_cmd_opt('texOptTikzpic', '', '@texClusterTikzset')

  syntax match texTikzSemicolon /;/ contained

  highlight def link texTikzSemicolon texDelim
endfunction

" }}}1
