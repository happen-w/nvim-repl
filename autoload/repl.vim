""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OriginalAuthor: Samuel Roeca
" Maintainer:     Samuel Roeca samuel.roeca@gmail.com
" Description:    nvim-repl: configure and work with a repl
" License:        MIT License
" Website:        https://github.com/pappasam/nvim-repl
" License:        MIT
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:id_window = v:false
let s:id_job = v:false

function! s:cleanup()
  call jobstop(s:id_job)
  let s:id_window = v:false
  let s:id_job = v:false
  echom 'Repl: closed!'
endfunction

function! s:setup()
  setlocal nonumber nornu nobuflisted
  autocmd WinClosed <buffer> call s:cleanup()
endfunction

function! s:repl_reset_visual_position()
  set lazyredraw
  let current_window_id = win_getid()
  call win_gotoid(s:id_window)
  normal! G
  call win_gotoid(current_window_id)
  set nolazyredraw
  redraw
endfunction

function! repl#open(...)
  if s:id_window != v:false
    echom 'Repl: already open. To close existing repl, run ":ReplClose"'
    return
  endif
  let current_window_id = win_getid()
  let func_args = a:000
  let command = len(func_args) == 0 ?
        \ get(g:repl_filetype_commands, &filetype, g:repl_default) :
        \ func_args[0]
  if &columns >= 160
    vert new
  else
    split new
  endif
  let s:id_job = termopen(command)
  let s:id_window = win_getid()
  call s:setup()
  call win_gotoid(current_window_id)
  echom 'Repl: opened!'
endfunction

function! repl#close()
  let current_window_id = win_getid()
  call win_gotoid(s:id_window)
  quit
  call win_gotoid(current_window_id)
endfunction

function! repl#toggle()
  if s:id_window == v:false
    call repl#open()
  else
    call repl#close()
  endif
endfunction

function! repl#send() range
  if s:id_window == v:false
    echom 'Repl: no repl currently open. Run ":ReplOpen" first'
    return
  endif
  let buflines_raw = getbufline(bufnr('%'), a:firstline, a:lastline)
  " handle cleaned, single empty lines correctly in Python / indented languages
  let buflines_clean = []
  let bufline_prev = a:firstline == 1 ?
        \ '' :
        \ getbufline(bufnr('%'), a:firstline - 1)[0]
  for bufline_raw in buflines_raw
    let bufline_clean = bufline_raw == '' && bufline_prev != '' ?
          \ matchstr(bufline_prev, '^\s\+') . bufline_raw :
          \ bufline_raw
    let buflines_clean = buflines_clean + [bufline_clean]
    let bufline_prev = bufline_raw
  endfor
  let buflines_chansend =
        \ a:lastline == line('$') && match(buflines_clean[-1], '^\s\+') == 0 ?
        \ buflines_clean + ['', ''] :
        \ buflines_clean + ['']
  call chansend(s:id_job, buflines_chansend)
  call s:repl_reset_visual_position()
endfunction