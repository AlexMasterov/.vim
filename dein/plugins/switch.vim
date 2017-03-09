nnoremap <silent> <S-Tab> :<C-u>silent! Switch<CR>
xnoremap <silent> <S-Tab> :silent! Switch<CR>
nnoremap <silent> ! :<C-u>call switch#Switch({'definitions': g:switchQuotes, 'reverse': 1})<CR>
nnoremap <silent> @ :<C-u>call switch#Switch({'definitions': g:switchCamelCase, 'reverse': 1})<CR>

let g:switchQuotes = [
  \ {
  \  "'\\(.\\{-}\\)'": '"\1"',
  \  '"\(.\{-}\)"': "'\\1'",
  \  '`\(.\{-}\)`': "'\\1'"
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